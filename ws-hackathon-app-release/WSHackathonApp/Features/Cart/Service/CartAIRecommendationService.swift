//
//  CartAIRecommendationService.swift
//  WSHackathonApp
//
//  Uses Gemini to suggest complementary bundle products for cart items.
//

import Foundation
import GoogleGenerativeAI

actor CartAIRecommendationService {
    static let shared = CartAIRecommendationService()

    private struct RecommendationIDsResponse: Decodable {
        let productIDs: [String]

        enum CodingKeys: String, CodingKey {
            case productIDs = "product_ids"
        }
    }

    private let model: GenerativeModel
    private let apiKey: String

    private init() {
        let apiKey = Self.getGeminiAPIKey()
        self.apiKey = apiKey
        self.model = GenerativeModel(
            name: "gemini-2.5-flash",
            apiKey: apiKey,
            generationConfig: GenerationConfig(
                responseMIMEType: "application/json"
            )
        )
    }

    func recommendations(
        for cartProduct: WSProduct,
        cartProducts: [WSProduct],
        catalog: [WSProduct],
        limit: Int = 4
    ) async -> [WSProduct] {
        let cartProductIDs = Set(cartProducts.map(\.id))
        let candidates = Array(
            catalog
                .filter { !cartProductIDs.contains($0.id) }
                .prefix(120)
        )

        guard !candidates.isEmpty else { return [] }

        guard !apiKey.isEmpty else {
            return fallbackRecommendations(
                for: cartProduct,
                candidates: candidates,
                limit: limit
            )
        }

        let prompt = buildPrompt(
            for: cartProduct,
            cartProducts: cartProducts,
            candidates: candidates,
            limit: limit
        )

        do {
            let response = try await model.generateContent(prompt)
            guard let text = response.text else {
                return fallbackRecommendations(for: cartProduct, candidates: candidates, limit: limit)
            }

            let cleanedText = text
                .replacingOccurrences(of: "```json\n", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let data = cleanedText.data(using: .utf8) else {
                return fallbackRecommendations(for: cartProduct, candidates: candidates, limit: limit)
            }

            let decoded = try JSONDecoder().decode(RecommendationIDsResponse.self, from: data)
            let productsByID = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id.uuidString.lowercased(), $0) })
            var seenIDs = Set<String>()

            let matchedProducts = decoded.productIDs.compactMap { rawID -> WSProduct? in
                let id = rawID.lowercased()
                guard !seenIDs.contains(id), let product = productsByID[id] else { return nil }
                seenIDs.insert(id)
                return product
            }

            if matchedProducts.isEmpty {
                return fallbackRecommendations(for: cartProduct, candidates: candidates, limit: limit)
            }

            return Array(matchedProducts.prefix(limit))
        } catch {
            return fallbackRecommendations(for: cartProduct, candidates: candidates, limit: limit)
        }
    }
}

private extension CartAIRecommendationService {
    nonisolated static func getGeminiAPIKey() -> String {
        if let path = Bundle.main.path(forResource: ".env", ofType: nil),
           let content = try? String(contentsOfFile: path) {
            for line in content.components(separatedBy: .newlines) {
                let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                if parts.count == 2, parts[0] == "GEMINI_API_KEY" {
                    let val = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !val.isEmpty { return val }
                }
            }
        }

        return "AIzaSyCr_-XV8F9RkYdAZK9WieCFCN9MP5azYbE"
    }

    func buildPrompt(
        for cartProduct: WSProduct,
        cartProducts: [WSProduct],
        candidates: [WSProduct],
        limit: Int
    ) -> String {
        let cartSummary = cartProducts.map { product in
            "- \(product.name) (\(product.category))"
        }.joined(separator: "\n")

        let catalog = candidates.map { product in
            """
            {
              "id": "\(product.id.uuidString)",
              "name": "\(escapeJSONString(product.name))",
              "category": "\(escapeJSONString(product.category))",
              "price": \(product.salePrice ?? product.price),
              "description": "\(escapeJSONString(product.description))"
            }
            """
        }.joined(separator: ",\n")

        return """
        You are a Williams Sonoma product bundling assistant.
        Recommend products that complete a practical set with the target cart item.
        Example: if the target item is a plate or dinnerware, recommend spoons, forks, flatware, napkins, or glassware.
        Return only product IDs from the provided catalog.
        Do not return explanations, markdown, or extra text.

        Target cart item:
        - Name: \(cartProduct.name)
        - Category: \(cartProduct.category)
        - Description: \(cartProduct.description)

        Current cart:
        \(cartSummary)

        Candidate catalog:
        [
        \(catalog)
        ]

        Return this JSON only:
        {
          "product_ids": ["id1", "id2"]
        }

        Rules:
        - Return at most \(limit) product IDs.
        - Choose complementary items that help complete a bundle or set.
        - Do not choose duplicate versions of the target item.
        - Every returned value must exactly match a provided product id.
        """
    }

    func fallbackRecommendations(
        for cartProduct: WSProduct,
        candidates: [WSProduct],
        limit: Int
    ) -> [WSProduct] {
        let cartText = searchableText(for: cartProduct)
        let desiredKeywords = complementaryKeywords(for: cartText)
        let desiredCategories = complementaryCategories(for: cartText)
        let cartTokens = Set(Self.tokenize(cartText))

        let scoredCandidates = candidates
            .map { product -> (product: WSProduct, score: Double) in
                let productText = searchableText(for: product)
                let productTokens = Set(Self.tokenize(productText))
                let productCategory = product.category.lowercased()
                
                // Start score at 0. Don't use rating as the primary base.
                var score = 0.0

                // Strong boost for matching a desired complementary category
                if desiredCategories.contains(where: { productCategory.contains($0) }) {
                    score += 10
                }

                // Boost for every matching complementary keyword
                let keywordMatches = desiredKeywords.filter { productText.contains($0) }.count
                score += Double(keywordMatches) * 5

                // Small boost for token overlap
                score += Double(productTokens.intersection(cartTokens).count) * 0.5
                
                // Tie-breaker boost for highly rated items
                score += product.rating * 0.1

                // Penalize if it's exactly the same category (we want complementary items, not identical ones)
                if product.category == cartProduct.category {
                    score -= 5
                }

                // Heavily penalize items with the exact same name
                if product.name == cartProduct.name {
                    score -= 100
                }

                return (product, score)
            }
            .filter { $0.score > 2.0 } // Must have at least some relevance (e.g. matched a keyword or category)
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.product.rating > rhs.product.rating
                }
                return lhs.score > rhs.score
            }

        return Array(scoredCandidates.prefix(limit).map(\.product))
    }

    func complementaryKeywords(for text: String) -> [String] {
        if containsAny(text, ["plate", "dinnerware", "tabletop", "bowl", "serveware", "dining"]) {
            return ["spoon", "fork", "flatware", "cutlery", "napkin", "glass", "mug", "tumbler", "placemat"]
        }

        if containsAny(text, ["knife", "cutlery", "chef"]) {
            return ["cutting board", "sharpener", "shears", "block", "utensil"]
        }

        if containsAny(text, ["cookware", "pan", "skillet", "oven", "cooker", "pot"]) {
            return ["utensil", "spatula", "oil", "salt", "pepper", "cutting board", "knife", "mitt"]
        }

        if containsAny(text, ["bake", "muffin", "cookie", "sheet", "cake"]) {
            return ["measuring", "mixer", "spatula", "dessert", "pan", "oven", "cooling"]
        }

        if containsAny(text, ["coffee", "espresso", "tea"]) {
            return ["mug", "cup", "coffee", "tea", "dessert", "spoon"]
        }

        if containsAny(text, ["blender", "mixer", "electric"]) {
            return ["cup", "spatula", "measuring", "dessert", "coffee"]
        }

        return ["utensil", "spoon", "cutting board", "measuring", "serve", "coffee"]
    }

    func complementaryCategories(for text: String) -> [String] {
        if containsAny(text, ["plate", "dinnerware", "tabletop", "bowl", "serveware", "dining"]) {
            return ["cutlery", "kitchen tools", "tabletop", "food"]
        }

        if containsAny(text, ["knife", "cutlery", "chef"]) {
            return ["kitchen tools", "cutlery"]
        }

        if containsAny(text, ["cookware", "pan", "skillet", "oven", "cooker", "pot"]) {
            return ["kitchen tools", "cutlery", "food"]
        }

        if containsAny(text, ["bake", "muffin", "cookie", "sheet", "cake"]) {
            return ["kitchen tools", "electrics", "food"]
        }

        if containsAny(text, ["coffee", "espresso", "tea"]) {
            return ["tabletop", "food", "kitchen tools"]
        }

        if containsAny(text, ["blender", "mixer", "electric"]) {
            return ["kitchen tools", "food", "tabletop"]
        }

        return ["kitchen tools", "tabletop", "cutlery"]
    }

    func searchableText(for product: WSProduct) -> String {
        "\(product.name) \(product.category) \(product.subcategory ?? "") \(product.description) \(product.specs.values.joined(separator: " "))"
            .lowercased()
    }

    func containsAny(_ text: String, _ values: [String]) -> Bool {
        values.contains { text.contains($0) }
    }

    func escapeJSONString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    static func tokenize(_ text: String) -> [String] {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 1 }
    }
}
