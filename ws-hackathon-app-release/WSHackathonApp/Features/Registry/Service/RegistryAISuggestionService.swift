import Foundation
import GoogleGenerativeAI

actor RegistryAISuggestionService {
    static let shared = RegistryAISuggestionService()

    private struct SuggestedProductIDsResponse: Decodable {
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

    func suggestProductIDs(
        for registry: Registry,
        products: [RegistryProduct],
        limit: Int = 10
    ) async throws -> [String] {
        guard !products.isEmpty else { return [] }

        let cappedProducts = Array(products.prefix(120))
        guard !apiKey.isEmpty else {
            return fallbackProductIDs(for: registry, products: cappedProducts, limit: limit)
        }

        let prompt = buildPrompt(for: registry, products: cappedProducts, limit: limit)
        do {
            let response = try await model.generateContent(prompt)

            guard let text = response.text else {
                return fallbackProductIDs(for: registry, products: cappedProducts, limit: limit)
            }

            let cleanedText = text
                .replacingOccurrences(of: "```json\n", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let jsonString = extractJSONObject(from: cleanedText) ?? cleanedText
            guard let data = jsonString.data(using: .utf8) else {
                return fallbackProductIDs(for: registry, products: cappedProducts, limit: limit)
            }

            let decoded = try JSONDecoder().decode(SuggestedProductIDsResponse.self, from: data)
            let productsByID = Dictionary(uniqueKeysWithValues: cappedProducts.compactMap { p -> (String, RegistryProduct)? in
                guard let id = p.supabaseId else { return nil }
                return (id.lowercased(), p)
            })

            var matchedIDs: [String] = []
            var seenIDs = Set<String>()

            for rawID in decoded.productIDs {
                let id = rawID.lowercased()
                if productsByID[id] != nil && !seenIDs.contains(id) {
                    seenIDs.insert(id)
                    matchedIDs.append(id)
                }
            }

            if matchedIDs.isEmpty {
                return fallbackProductIDs(for: registry, products: cappedProducts, limit: limit)
            }

            return matchedIDs
        } catch {
            return fallbackProductIDs(for: registry, products: cappedProducts, limit: limit)
        }
    }

    private func extractJSONObject(from value: String) -> String? {
        guard let start = value.firstIndex(of: "{"),
              let end = value.lastIndex(of: "}") else {
            return nil
        }
        return String(value[start...end])
    }
}

private extension RegistryAISuggestionService {
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

    func buildPrompt(for registry: Registry, products: [RegistryProduct], limit: Int) -> String {
        let plannerAnswers = registry.registryType == .event
            ? registry.eventDetails.aiPlannerAnswers
            : registry.giftingDetails.aiPlannerAnswers

        let plannerSummary = plannerAnswers
            .filter { $0.question != Self.primaryPurposeQuestion }
            .map { answer -> String in
                let selected = answer.answers.sorted().joined(separator: ", ")
                let freeText = answer.answer.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalAnswer = freeText.isEmpty ? selected : freeText
                return "- \(answer.question): \(finalAnswer.isEmpty ? "Not specified" : finalAnswer)"
            }
            .joined(separator: "\n")

        let budgetValue: Double = {
            if registry.registryType == .event {
                return registry.eventDetails.targetBudget
            }
            return registry.giftingDetails.splitType == .split
                ? registry.giftingDetails.creatorBudget
                : registry.giftingDetails.pooledBudget
        }()

        let productCatalog = products.map { product in
            """
            {
              "id": "\(product.supabaseId ?? product.skuId)",
              "name": "\(escapeJSONString(product.name))",
              "category": "\(escapeJSONString(product.category))",
              "price": \(product.price)
            }
            """
        }.joined(separator: ",\n")

        return """
        You are selecting Williams-Sonoma products for a registry.
        Choose the best matching products based on the registry details and planner answers.
        Return only product IDs from the provided catalog.
        Do not return explanations, descriptions, reasoning, markdown, or any extra text.

        Registry:
        - Registry type: \(registry.registryType.rawValue)
        - Event type: \(registry.eventType.rawValue)
        - Primary purpose: \(registry.eventType.title)
        - Registry name: \(registry.name)
        - Creator name: \(registry.creatorName)
        - Date: \(registry.eventDate.formatted(date: .abbreviated, time: .omitted))
        - Currency: \(registry.currency.code)
        - Budget: \(budgetValue)
        - Collaborators: \(registry.giftingDetails.collaboratorCount)

        Planner answers:
        \(plannerSummary.isEmpty ? "- None" : plannerSummary)

        Product catalog:
        [
        \(productCatalog)
        ]

        Return this JSON only:
        {
          "product_ids": ["id1", "id2"]
        }

        Rules:
        - Return at most \(limit) product IDs.
        - Prefer products that strongly match the answers.
        - Stay reasonably aligned with the budget.
        - Every returned value must exactly match a provided product id.
        """
    }

    func jsonArrayString(from values: [String]) -> String {
        let escaped = values.map { "\"\(escapeJSONString($0))\"" }
        return "[\(escaped.joined(separator: ", "))]"
    }

    func escapeJSONString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    func fallbackProductIDs(
        for registry: Registry,
        products: [RegistryProduct],
        limit: Int
    ) -> [String] {
        let plannerAnswers = registry.registryType == .event
            ? registry.eventDetails.aiPlannerAnswers
            : registry.giftingDetails.aiPlannerAnswers

        let answerTokens = Set(
            plannerAnswers
                .flatMap { answer in
                    let selected = Array(answer.answers)
                    let freeText = answer.answer.isEmpty ? [] : [answer.answer]
                    return (selected + freeText)
                }
                .flatMap(Self.tokenize)
        )

        let categoryHints = Set(suggestedCategories(for: registry, answerTokens: answerTokens))
        let budgetValue: Double = {
            if registry.registryType == .event {
                return registry.eventDetails.targetBudget
            }
            let gifting = registry.giftingDetails
            return gifting.splitType == .split ? gifting.creatorBudget : gifting.pooledBudget
        }()

        return products
            .compactMap { product -> (String, Double)? in
                guard let productID = product.supabaseId else { return nil }
                let searchableText = "\(product.name) \(product.category) \(product.specs.joined(separator: " "))".lowercased()
                let productTokens = Set(Self.tokenize(searchableText))
                var score = 0.0

                if categoryHints.contains(product.category.lowercased()) {
                    score += 4
                }

                score += Double(productTokens.intersection(answerTokens).count) * 0.9

                if searchableText.contains(registry.eventType.title.lowercased()) {
                    score += 1.5
                }

                if budgetValue > 0 {
                    if product.price <= budgetValue {
                        score += 1
                    } else {
                        score -= min((product.price - budgetValue) / max(budgetValue, 1), 2.5)
                    }
                }

                score += product.stars * 0.15
                return (productID, score)
            }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0 < rhs.0
                }
                return lhs.1 > rhs.1
            }
            .prefix(limit)
            .map(\.0)
    }

    func suggestedCategories(for registry: Registry, answerTokens: Set<String>) -> [String] {
        var categories = Set<String>()

        switch registry.eventType {
        case .wedding:
            categories.formUnion(["cookware", "tabletop", "bakeware", "coffee & tea"])
        case .birthday:
            categories.formUnion(["bakeware", "food & pantry", "tabletop"])
        case .anniversary:
            categories.formUnion(["tabletop", "coffee & tea", "electrics"])
        case .babyShower:
            categories.formUnion(["tabletop", "storage & organization", "gifts & registry"])
        case .housewarming:
            categories.formUnion(["cookware", "kitchen tools", "electrics", "storage & organization"])
        case .graduation:
            categories.formUnion(["electrics", "coffee & tea", "kitchen tools"])
        case .farewell:
            categories.formUnion(["tabletop", "food & pantry", "coffee & tea"])
        case .festival:
            categories.formUnion(["tabletop", "food & pantry", "bakeware"])
        case .other:
            break
        }

        let tokenCategoryMap: [String: [String]] = [
            "cookware": ["cookware"],
            "bakeware": ["bakeware"],
            "electrics": ["electrics"],
            "tabletop": ["tabletop", "tabletop & bar"],
            "kitchen": ["kitchen tools"],
            "tools": ["kitchen tools"],
            "coffee": ["coffee & tea"],
            "tea": ["coffee & tea"],
            "storage": ["storage & organization"],
            "organization": ["storage & organization"],
            "outdoor": ["outdoor & bbq"],
            "bbq": ["outdoor & bbq"],
            "gifts": ["gifts & registry"],
            "registry": ["gifts & registry"]
        ]

        for token in answerTokens {
            if let mappedCategories = tokenCategoryMap[token] {
                categories.formUnion(mappedCategories)
            }
        }

        return Array(categories)
    }

    static func tokenize(_ text: String) -> [String] {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 1 }
    }

    static let primaryPurposeQuestion = "What is the primary purpose of this event?"
}
