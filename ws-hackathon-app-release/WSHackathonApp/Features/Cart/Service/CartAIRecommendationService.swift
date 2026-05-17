import Foundation
import GoogleGenerativeAI

actor CartAIRecommendationService {
    static let shared = CartAIRecommendationService()

    enum RecommendationOutcome {
        case success([WSProduct])
        case noMatches
        case unavailable
    }

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
            name: "gemini-1.5-flash",
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
    ) async -> RecommendationOutcome {
        let cartProductIDs = Set(cartProducts.map(\.id))
        let candidates = Array(
            catalog
                .filter { !cartProductIDs.contains($0.id) }
                .prefix(120)
        )

        guard !candidates.isEmpty else { return .noMatches }
        guard !apiKey.isEmpty else { return .unavailable }

        let prompt = buildPrompt(
            for: cartProduct,
            cartProducts: cartProducts,
            candidates: candidates,
            limit: limit
        )

        do {
            let response = try await model.generateContent(prompt)
            guard let text = response.text else { return .unavailable }

            let cleanedText = text
                .replacingOccurrences(of: "```json\n", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let jsonString = extractJSONObject(from: cleanedText) ?? cleanedText
            guard let data = jsonString.data(using: .utf8) else { return .unavailable }

            let decoded = try JSONDecoder().decode(RecommendationIDsResponse.self, from: data)
            let productsByID = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id.uuidString.lowercased(), $0) })
            var seenIDs = Set<String>()

            let matchedProducts = decoded.productIDs.compactMap { rawID -> WSProduct? in
                let id = rawID.lowercased()
                guard !seenIDs.contains(id), let product = productsByID[id] else { return nil }
                seenIDs.insert(id)
                return product
            }

            if matchedProducts.isEmpty { return .noMatches }

            return .success(Array(matchedProducts.prefix(limit)))
        } catch {
            return .unavailable
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

    func escapeJSONString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    func extractJSONObject(from value: String) -> String? {
        guard let start = value.firstIndex(of: "{"),
              let end = value.lastIndex(of: "}") else {
            return nil
        }

        return String(value[start...end])
    }
}
