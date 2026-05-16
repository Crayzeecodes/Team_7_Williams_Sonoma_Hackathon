//
//  RegistryModels.swift
//  WSHackathonApp
//

import Foundation

struct RegistryPlannerAnswer: Codable, Hashable, Identifiable {
    var id: String { question }
    let question: String
    var answer: String
    var options: [String]?
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
    let _id: String?
    let email: String?
    let name: String?

    var id: String { _id ?? email ?? UUID().uuidString }
}

struct RegistryProduct: Codable, Hashable, Identifiable {
    let _id: String?
    let skuId: String
    let name: String
    let description: String
    let price: Double
    let images: [String]
    let category: String
    let specs: [String]
    let stars: Double
    let reviews: [RegistryProductReview]
    let arModelUrl: String
    let arScale: Double
    let arPlacementType: String

    var id: String { _id ?? skuId }

    var primaryImageURL: URL? {
        guard let first = images.first else { return nil }
        if first.hasPrefix("http") {
            return URL(string: first)
        }
        return APIConfig.baseURL.appendingPathComponent(first.hasPrefix("/") ? String(first.dropFirst()) : first)
    }
}

struct RegistryProductReview: Codable, Hashable, Identifiable {
    var id: String { "\(userId.rawValue)-\(createdAt?.timeIntervalSince1970 ?? 0)" }
    let userId: RegistryUserReference
    let rating: Int
    let comment: String
    let createdAt: Date?
}

struct RegistryUserReference: Codable, Hashable {
    let rawValue: String
    let user: RegistryUserSummary?

    init(rawValue: String, user: RegistryUserSummary? = nil) {
        self.rawValue = rawValue
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .init(rawValue: value, user: nil)
        } else {
            let user = try container.decode(RegistryUserSummary.self)
            self = .init(rawValue: user._id ?? user.email ?? "", user: user)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
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
            self = .init(rawValue: product._id ?? product.skuId, product: product)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct RegistryMember: Codable, Hashable, Identifiable {
    var id: String { userId.rawValue }
    let userId: RegistryUserReference
    let role: RegistryMemberRole
    let contributedBudget: Double
    let joinedAt: Date?

    var displayName: String {
        userId.user?.name ?? "Member"
    }
}

struct RegistryCartItem: Codable, Hashable, Identifiable {
    let id: String
    let productId: RegistryProductReference
    let addedByUserId: RegistryUserReference
    let quantity: Int
    let price: Double
    let name: String
    let imageUrl: String
    let source: RegistryCartItemSource
    let status: RegistryCartItemStatus
    let addedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case productId
        case addedByUserId
        case quantity
        case price
        case name
        case imageUrl
        case source
        case status
        case addedAt
    }

    var imageURL: URL? {
        if imageUrl.hasPrefix("http") {
            return URL(string: imageUrl)
        }
        let cleaned = imageUrl.hasPrefix("/") ? String(imageUrl.dropFirst()) : imageUrl
        return APIConfig.baseURL.appendingPathComponent(cleaned)
    }
}

struct RegistryAISuggestion: Codable, Hashable, Identifiable {
    var id: String { "\(productId.rawValue)-\(generatedAt?.timeIntervalSince1970 ?? 0)" }
    let productId: RegistryProductReference
    let score: Double
    let reasoning: String
    let generatedAt: Date?
}

struct RegistryPollVote: Codable, Hashable {
    let userId: RegistryUserReference
}

struct RegistryPollOption: Codable, Hashable {
    let productId: RegistryProductReference
    let votes: [RegistryPollVote]
}

struct RegistryPoll: Codable, Hashable, Identifiable {
    var id: String { "\(question)-\(createdAt?.timeIntervalSince1970 ?? 0)" }
    let question: String
    let options: [RegistryPollOption]
    let status: RegistryPollStatus
    let createdAt: Date?
}

struct RegistryBudgetSnapshot: Codable, Hashable {
    let totalBudget: Double
    let spentAmount: Double
    let remainingAmount: Double
    let lastUpdated: Date?
}

struct Registry: Codable, Hashable, Identifiable {
    let _id: String?
    let adminId: RegistryUserReference
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

    var id: String { _id ?? joinCode }

    var isEventRegistry: Bool { registryType == .event }

    var collaboratorCountText: String {
        let count = max(0, members.count - 1)
        return "\(count) contributor\(count == 1 ? "" : "s")"
    }
}

struct RegistryPreview: Codable, Hashable, Identifiable {
    let _id: String?
    let name: String
    let joinCode: String
    let registryType: RegistryType
    let creatorName: String
    let eventType: RegistryEventType
    let eventDate: Date
    let currency: CurrencyInfo
    let giftingDetails: RegistryGiftingDetailsPreview?

    var id: String { _id ?? joinCode }
}

struct RegistryGiftingDetailsPreview: Codable, Hashable {
    let budgetStatus: RegistryGiftingBudgetStatus
    let splitType: RegistryPaymentSplitType
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

struct RegistryMemberDisplay: Codable, Hashable, Identifiable {
    var id: String { userId }
    let userId: String
    let name: String
    let joinedAt: Date?
    let contributedBudget: Double
    let role: RegistryMemberRole
}

struct CreateRegistryRequest: Codable, Hashable {
    let adminId: String?
    let name: String
    let joinCode: String?
    let registryType: RegistryType
    let creatorName: String
    let eventType: RegistryEventType
    let eventDate: Date
    let currency: CurrencyInfo
    let eventDetails: RegistryEventDetails
    let giftingDetails: RegistryGiftingDetails
    let members: [RegistryMemberRequest]
    let cartItems: [RegistryCartItemRequest]
    let aiSuggestions: [RegistryAISuggestionRequest]
    let polls: [RegistryPollRequest]
    let budgetSnapshot: RegistryBudgetSnapshot
    let shippingAddress: String
    let createdAt: Date?
}

struct RegistryMemberRequest: Codable, Hashable {
    let userId: String
    let role: RegistryMemberRole
    let contributedBudget: Double
    let joinedAt: Date
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

struct RegistryAISuggestionRequest: Codable, Hashable {
    let productId: String
    let score: Double
    let reasoning: String
    let generatedAt: Date
}

struct RegistryPollVoteRequest: Codable, Hashable {
    let userId: String
}

struct RegistryPollOptionRequest: Codable, Hashable {
    let productId: String
    let votes: [RegistryPollVoteRequest]
}

struct RegistryPollRequest: Codable, Hashable {
    let question: String
    let options: [RegistryPollOptionRequest]
    let status: RegistryPollStatus
    let createdAt: Date
}

struct JoinRegistryRequest: Codable, Hashable {
    let joinCode: String
    let contributedBudget: Double?
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

struct RegistrySuggestionRefreshRequest: Codable, Hashable {
    let forceRefresh: Bool
}

extension Registry {
    static var emptyBudgetSnapshot: RegistryBudgetSnapshot {
        RegistryBudgetSnapshot(totalBudget: 0, spentAmount: 0, remainingAmount: 0, lastUpdated: nil)
    }
}
