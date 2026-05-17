
import Foundation

struct RegistryPlannerAnswer: Codable, Hashable, Identifiable {
    var id: String { question }
    let question: String
    var answer: String
    var answers: Set<String> = []
    var options: [String]?
    var allowsMultiple: Bool = false
}

struct RegistryPlannerQuestion: Identifiable {
    var id: String { question }
    let question: String
    let options: [String]
    let placeholder: String
}

struct CurrencyInfo: Codable, Hashable {
    let code: String
    let symbol: String
}

enum RegistryType: String, Codable, CaseIterable, Hashable {
    case event
    case gifting

    var title: String {
        switch self {
        case .event: return "Event"
        case .gifting: return "Gifting"
        }
    }
}

enum RegistryFilter: String, CaseIterable, Hashable {
    case all
    case events
    case gifting

    var title: String {
        switch self {
        case .all: return "All"
        case .events: return "Events"
        case .gifting: return "Gifting"
        }
    }
}

enum RegistryEventType: String, Codable, CaseIterable, Hashable {
    case birthday
    case anniversary
    case wedding
    case babyShower = "baby_shower"
    case graduation
    case housewarming
    case farewell
    case festival
    case other

    var title: String {
        switch self {
        case .birthday: return "Birthday"
        case .anniversary: return "Anniversary"
        case .wedding: return "Wedding"
        case .babyShower: return "Baby Shower"
        case .graduation: return "Graduation"
        case .housewarming: return "Housewarming"
        case .farewell: return "Farewell"
        case .festival: return "Festival"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .birthday: return "birthday.cake.fill"
        case .anniversary: return "heart.fill"
        case .wedding: return "sparkles"
        case .babyShower: return "figure.2.and.child.holdinghands"
        case .graduation: return "graduationcap.fill"
        case .housewarming: return "house.fill"
        case .farewell: return "hands.and.sparkles.fill"
        case .festival: return "gift.fill"
        case .other: return "party.popper.fill"
        }
    }
}

enum RegistryPaymentSplitType: String, Codable, CaseIterable, Hashable {
    case split
    case dutch

    var title: String {
        rawValue == "split" ? "Split equally" : "Dutch"
    }
}

enum RegistryMemberRole: String, Codable, Hashable {
    case admin
    case collaborator
}

enum RegistryCartItemSource: String, Codable, Hashable {
    case manual
    case ai
}

enum RegistryCartItemStatus: String, Codable, Hashable {
    case inCart = "in_cart"
    case purchased
}

enum RegistryGiftingBudgetStatus: String, Codable, Hashable {
    case pending
    case finalized
}

enum RegistryPollStatus: String, Codable, Hashable {
    case active
    case closed
}

struct RegistryEventDetails: Codable, Hashable {
    var aiPlannerAnswers: [RegistryPlannerAnswer]
    var targetBudget: Double
    var paymentSplitType: RegistryPaymentSplitType

}

struct RegistryGiftingDetails: Codable, Hashable {
    var collaboratorCount: Int
    var aiPlannerAnswers: [RegistryPlannerAnswer]
    var splitType: RegistryPaymentSplitType
    var creatorBudget: Double
    var pooledBudget: Double
    var budgetStatus: RegistryGiftingBudgetStatus
}

struct RegistryUserSummary: Codable, Hashable, Identifiable {
    let id: String?
    let email: String?
    let name: String?

    var stableId: String { id ?? email ?? UUID().uuidString }
}

struct RegistryProduct: Codable, Hashable, Identifiable {
    let supabaseId: String?
    let skuId: String
    let name: String
    let description: String
    let price: Double
    let images: [String]
    let category: String
    let specs: [String]
    let stars: Double
    let arModelUrl: String?
    let arScale: Double?
    let arPlacementType: String?

    enum CodingKeys: String, CodingKey {
        case supabaseId = "id"
        case skuId = "sku_id"
        case name
        case description
        case price
        case images
        case category
        case specs
        case stars
        case arModelUrl = "ar_model_url"
        case arScale = "ar_scale"
        case arPlacementType = "ar_placement_type"
    }

    var id: String { supabaseId ?? skuId }

    var primaryImageURL: URL? {
        guard let first = images.first else { return nil }
        if first.hasPrefix("http") {
            return URL(string: first)
        }
        return APIConfig.baseURL.appendingPathComponent(first.hasPrefix("/") ? String(first.dropFirst()) : first)
    }
}

struct RegistryProductReference: Codable, Hashable {
    let rawValue: String
    let product: RegistryProduct?

    init(rawValue: String, product: RegistryProduct? = nil) {
        self.rawValue = rawValue
        self.product = product
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .init(rawValue: value, product: nil)
        } else {
            let product = try container.decode(RegistryProduct.self)
            self = .init(rawValue: product.supabaseId ?? product.skuId, product: product)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct Registry: Codable, Hashable, Identifiable {
    let supabaseId: String?

    let adminId: String
    let name: String
    let joinCode: String
    let registryType: RegistryType
    let creatorName: String
    let eventType: RegistryEventType
    let eventDate: Date
    let currency: CurrencyInfo
    let eventDetails: RegistryEventDetails
    let giftingDetails: RegistryGiftingDetails

    let members: [RegistryMember]
    let cartItems: [RegistryCartItem]
    let aiSuggestions: [RegistryAISuggestion]
    let polls: [RegistryPoll]
    let budgetSnapshot: RegistryBudgetSnapshot
    let shippingAddress: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case supabaseId = "id"
        case adminId = "admin_id"
        case name
        case joinCode = "join_code"
        case registryType = "registry_type"
        case creatorName = "creator_name"
        case eventType = "event_type"
        case eventDate = "event_date"
        case currency
        case eventDetails = "event_details"
        case giftingDetails = "gifting_details"
        case members
        case cartItems = "cart_items"
        case aiSuggestions = "ai_suggestions"
        case polls
        case budgetSnapshot = "budget_snapshot"
        case shippingAddress = "shipping_address"
        case createdAt = "created_at"
    }

    var id: String { supabaseId ?? joinCode }

    var isEventRegistry: Bool { registryType == .event }

    var collaboratorCountText: String {
        let count = max(0, members.count - 1)
        return "\(count) contributor\(count == 1 ? "" : "s")"
    }
}

struct RegistryMember: Codable, Hashable, Identifiable {
    var id: String { userId }
    let userId: String
    let role: RegistryMemberRole
    let contributedBudget: Double
    let joinedAt: Date?

    var displayName: String { "Member" }
}

struct RegistryCartItem: Codable, Hashable, Identifiable {
    let id: String
    let productId: String
    let addedByUserId: String
    let quantity: Int
    let price: Double
    let name: String
    let imageUrl: String
    let source: RegistryCartItemSource
    let status: RegistryCartItemStatus
    let addedAt: Date?

    var imageURL: URL? {
        if imageUrl.hasPrefix("http") {
            return URL(string: imageUrl)
        }
        let cleaned = imageUrl.hasPrefix("/") ? String(imageUrl.dropFirst()) : imageUrl
        return APIConfig.baseURL.appendingPathComponent(cleaned)
    }
}

struct RegistryAISuggestion: Codable, Hashable, Identifiable {
    var id: String { "\(productId)-\(generatedAt?.timeIntervalSince1970 ?? 0)" }
    let productId: String
    let score: Double
    let reasoning: String
    let generatedAt: Date?

    var productRef: RegistryProductReference { RegistryProductReference(rawValue: productId) }
}

struct RegistryPollVote: Codable, Hashable {
    let userId: String
}

struct RegistryPollOption: Codable, Hashable {
    let productId: String
    let votes: [RegistryPollVote]
}

struct RegistryPoll: Codable, Hashable, Identifiable {
    let pollId: String?
    let question: String
    let options: [RegistryPollOption]
    let status: RegistryPollStatus
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case pollId = "id"
        case question
        case options
        case status
        case createdAt
    }

    var id: String { pollId ?? "\(question)-\(createdAt?.timeIntervalSince1970 ?? 0)" }
}

struct RegistryBudgetSnapshot: Codable, Hashable {
    let totalBudget: Double
    let spentAmount: Double
    let remainingAmount: Double
    let lastUpdated: Date?
}

struct RegistryPreview: Codable, Hashable, Identifiable {
    let supabaseId: String?
    let name: String
    let joinCode: String
    let registryType: RegistryType
    let creatorName: String
    let eventType: RegistryEventType
    let eventDate: Date
    let currency: CurrencyInfo
    let giftingDetails: RegistryGiftingDetails?

    enum CodingKeys: String, CodingKey {
        case supabaseId = "id"
        case name
        case joinCode = "join_code"
        case registryType = "registry_type"
        case creatorName = "creator_name"
        case eventType = "event_type"
        case eventDate = "event_date"
        case currency
        case giftingDetails = "gifting_details"
    }

    var id: String { supabaseId ?? joinCode }
}

struct RegistryMemberDisplay: Codable, Hashable, Identifiable {
    var id: String { userId }
    let userId: String
    let joinedAt: Date?
    let contributedBudget: Double
    let role: RegistryMemberRole
    var name: String?
    var email: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case joinedAt = "joined_at"
        case contributedBudget = "contributed_budget"
        case role
        case name
        case email
    }

    var displayName: String {
        if let name, !name.isEmpty { return name }
        if let email, !email.isEmpty { return email }
        return "Member"
    }
}

struct CartUpdatePayload: Codable, Hashable {
    let registryId: String
    let cartItems: [RegistryCartItem]
    let budgetSnapshot: RegistryBudgetSnapshot
}

struct MemberPayload: Codable, Hashable {
    let registryId: String
    let member: RegistryMember?
    let userId: String?
}

struct CreateRegistryRequest: Codable, Hashable {
    let adminId: String
    let name: String
    let joinCode: String
    let registryType: RegistryType
    let creatorName: String
    let eventType: RegistryEventType
    let eventDate: Date
    let currency: CurrencyInfo
    let eventDetails: RegistryEventDetails
    let giftingDetails: RegistryGiftingDetails
    let budgetSnapshot: RegistryBudgetSnapshot
    let shippingAddress: String

    enum CodingKeys: String, CodingKey {
        case adminId = "admin_id"
        case name
        case joinCode = "join_code"
        case registryType = "registry_type"
        case creatorName = "creator_name"
        case eventType = "event_type"
        case eventDate = "event_date"
        case currency
        case eventDetails = "event_details"
        case giftingDetails = "gifting_details"
        case budgetSnapshot = "budget_snapshot"
        case shippingAddress = "shipping_address"
    }
}

struct RegistryMemberRequest: Codable, Hashable {
    let registryId: String
    let userId: String
    let role: RegistryMemberRole
    let contributedBudget: Double
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case registryId = "registry_id"
        case userId = "user_id"
        case role
        case contributedBudget = "contributed_budget"
        case joinedAt = "joined_at"
    }
}

struct RegistryCartItemRequest: Codable, Hashable {
    let productId: String
    let addedByUserId: String
    let quantity: Int
    let price: Double
    let name: String
    let imageUrl: String
    let source: RegistryCartItemSource
    let status: RegistryCartItemStatus
    let addedAt: Date
}

struct AddRegistryCartItemRequest: Codable, Hashable {
    let productId: String
    let quantity: Int
    let price: Double?
    let name: String?
    let imageUrl: String?
    let source: RegistryCartItemSource
    let status: RegistryCartItemStatus
}

struct JoinRegistryRequest: Codable, Hashable {
    let joinCode: String
    let contributedBudget: Double?
}

struct RegistrySuggestionRefreshRequest: Codable, Hashable {
    let forceRefresh: Bool
}

extension Registry {
    static var emptyBudgetSnapshot: RegistryBudgetSnapshot {
        RegistryBudgetSnapshot(totalBudget: 0, spentAmount: 0, remainingAmount: 0, lastUpdated: nil)
    }
}
