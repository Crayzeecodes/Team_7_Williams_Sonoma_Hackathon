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
            let currentModel = GenerativeModel(
                name: "gemini-1.5-flash",
                apiKey: Self.getGeminiAPIKey(),
                generationConfig: GenerationConfig(responseMIMEType: "application/json")
            )
            let response = try await currentModel.generateContent(prompt)
            guard let text = response.text else { return .success(fallbackRecommendations(for: cartProduct, catalog: candidates, limit: limit)) }

            let cleanedText = text
                .replacingOccurrences(of: "```json\n", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let jsonString = extractJSONObject(from: cleanedText) ?? cleanedText
            guard let data = jsonString.data(using: .utf8) else { return .success(fallbackRecommendations(for: cartProduct, catalog: candidates, limit: limit)) }

            let decoded = try JSONDecoder().decode(RecommendationIDsResponse.self, from: data)
            let productsByID = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id.uuidString.lowercased(), $0) })
            var seenIDs = Set<String>()

            let matchedProducts = decoded.productIDs.compactMap { rawID -> WSProduct? in
                let id = rawID.lowercased()
                guard !seenIDs.contains(id), let product = productsByID[id] else { return nil }
                seenIDs.insert(id)
                return product
            }

            if matchedProducts.isEmpty { return .success(fallbackRecommendations(for: cartProduct, catalog: candidates, limit: limit)) }

            return .success(Array(matchedProducts.prefix(limit)))
        } catch {
            print("❌ Cart AI Recommendation Error: \(error.localizedDescription)")
            return .success(fallbackRecommendations(for: cartProduct, catalog: candidates, limit: limit))
        }
    }

    private func fallbackRecommendations(for cartProduct: WSProduct, catalog: [WSProduct], limit: Int) -> [WSProduct] {
        let cartCat = cartProduct.category.lowercased()
        
        var categoryScores = [(WSProduct, Double)]()
        for p in catalog {
            var score = 0.0
            let pCat = p.category.lowercased()
            
            // Bidirectional pairings
            if (cartCat.contains("electric") && pCat.contains("bakeware")) || 
               (cartCat.contains("bakeware") && pCat.contains("electric")) { score += 5 }
               
            else if (cartCat.contains("furniture") && pCat.contains("home essential")) || 
                    (cartCat.contains("home essential") && pCat.contains("furniture")) { score += 5 }
                    
            else if (cartCat.contains("cookware") && (pCat.contains("cook's tools") || pCat.contains("tools") || pCat.contains("food"))) || 
                    ((cartCat.contains("cook's tools") || cartCat.contains("tools") || cartCat.contains("food")) && pCat.contains("cookware")) { score += 5 }
                    
            else if cartCat.contains("cutlery") && pCat.contains("cutlery") { score += 5 }
            else if cartCat.contains("gift") && pCat.contains("gift") { score += 5 }
            
            // Minor score for other items just to have fallbacks
            else { score += 1 } 
            
            categoryScores.append((p, score))
        }
        
        let sorted = categoryScores.sorted { $0.1 > $1.1 }
        return Array(sorted.prefix(limit).map { $0.0 })
    }
}

private extension CartAIRecommendationService {
    nonisolated static func getGeminiAPIKey() -> String {
        return "AIzaSyAST0sV6uIXnSgpkxu5Tgi4U95Ruz3BlJk"
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
              "category": "\(escapeJSONString(product.category))"
            }
            """
        }.joined(separator: ",\n")

        return """
You are a smart product bundling engine for a premium home and kitchen retail store.

Your job is to recommend \(limit) products from the catalog that a customer would genuinely want to add alongside their selected item — based on real-world usage, function, and context.

---

TARGET ITEM (what the customer just added):
Name: \(cartProduct.name)
Category: \(cartProduct.category)
Description: \(cartProduct.description)
CURRENT CART:
\(cartSummary)

CANDIDATE CATALOG (items available to recommend):
\(catalog)
Each catalog entry includes: id, name, category, description, material, and use_case.

---

HOW TO REASON (think step by step before outputting):

1. UNDERSTAND the target item's primary use context.
   Ask: What task or setting is this product for? Where and how will it be used?
   Example: "Le Creuset Dutch Oven" → stovetop and oven cooking, high heat, needs matching lids or utensils.

2. FIND items in the catalog that share the same use context or directly complement it.
   Ask: Would someone using this product also need or reach for that one?
   Examples:
   - Oven → recommend oven-safe bakeware, oven mitts, wire racks (NOT outdoor grills)
   - Couch → recommend sofa cushions, throw blankets, side tables (NOT garden planters)
   - Chef's knife → recommend a cutting board, honing rod, or knife block (NOT dinner plates)
   - Dinner plates → recommend matching bowls, serving platters, or placemats (NOT a stockpot)

3. AVOID over-broad category matching.
   A category like "Home Essentials" may contain both sofa cushions AND camping gear.
   Do NOT recommend based on shared category alone — reason about whether the specific product fits the specific context.

4. AVOID items already in the cart.

5. PRIORITIZE functional pairing over aesthetic pairing.
   Functional: this item makes the target item more useful or complete.
   Aesthetic: this item simply "looks nice with it."
   Functional always wins.

6. If the target item is a consumable (coffee, flour, seasoning), recommend the equipment that uses it.
   If the target is equipment (espresso machine, mixer), recommend consumables or accessories for it.

---

Return ONLY this JSON — no markdown, no explanation, no extra keys:
{
  "product_ids": ["id1", "id2"]
}        
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
