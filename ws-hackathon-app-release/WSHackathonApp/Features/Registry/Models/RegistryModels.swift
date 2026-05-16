// RegistryModels.swift
// WSHackathonApp
// Full Codable models matching the Mongoose Registry schema exactly.

import Foundation

// MARK: - Enums

enum RegistryType: String, Codable, CaseIterable, Hashable {
    case event = "event"
    case gifting = "gifting"
}

enum EventType: String, Codable, CaseIterable, Identifiable {
    case birthday = "birthday"
    case anniversary = "anniversary"
    case wedding = "wedding"
    case babyShower = "baby_shower"
    case graduation = "graduation"
    case housewarming = "housewarming"
    case farewell = "farewell"
    case festival = "festival"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .birthday:    return "Birthday"
        case .anniversary: return "Anniversary"
        case .wedding:     return "Wedding"
        case .babyShower:  return "Baby Shower"
        case .graduation:  return "Graduation"
        case .housewarming:return "Housewarming"
        case .farewell:    return "Farewell"
        case .festival:    return "Festival"
        case .other:       return "Other"
        }
    }

    /// SF Symbol name for this event type
    var sfSymbol: String {
        switch self {
        case .birthday:    return "birthday.cake"
        case .anniversary: return "heart.fill"
        case .wedding:     return "hands.and.sparkles.fill"
        case .babyShower:  return "figure.and.child.holdinghands"
        case .graduation:  return "graduationcap.fill"
        case .housewarming:return "house.fill"
        case .farewell:    return "airplane.departure"
        case .festival:    return "sparkles"
        case .other:       return "gift.fill"
        }
    }
}

enum SplitType: String, Codable, Hashable {
    case split = "split"
    case dutch = "dutch"
}

enum CartItemStatus: String, Codable, Hashable {
    case inCart = "in_cart"
    case purchased = "purchased"
}

enum ItemSource: String, Codable, Hashable {
    case manual = "manual"
    case ai = "ai"
}

enum MemberRole: String, Codable, Hashable {
    case admin = "admin"
    case collaborator = "collaborator"
}

enum BudgetStatus: String, Codable, Hashable {
    case pending = "pending"
    case finalized = "finalized"
}

// MARK: - Currency

struct CurrencyInfo: Codable, Equatable, Hashable {
    var code: String
    var symbol: String

    static let usd = CurrencyInfo(code: "USD", symbol: "$")
}

// MARK: - Sub-models

struct CartItemModel: Codable, Identifiable, Hashable {
    var id: String { _id ?? UUID().uuidString }
    let _id: String?
    let productId: String
    let addedByUserId: String
    var quantity: Int
    let price: Double
    let name: String
    let imageUrl: String?
    let source: ItemSource?
    let status: CartItemStatus?
    let addedAt: String?

    var displayImageURL: URL? {
        guard let img = imageUrl, !img.isEmpty else { return nil }
        return URL(string: AppConstants.API.imageBasePath + img)
    }
}

struct RegistryMember: Codable, Identifiable, Hashable {
    var id: String { _id ?? userId }
    let _id: String?
    let userId: String
    let role: MemberRole?
    var contributedBudget: Double?
    let joinedAt: String?

    var initials: String {
        let parts = userId.prefix(4)
        return String(parts).uppercased()
    }
}

struct AiSuggestion: Codable, Identifiable, Hashable {
    var id: String { _id ?? productId }
    let _id: String?
    let productId: String
    let score: Double
    let reasoning: String
    let generatedAt: String?
    // Enriched by /suggest endpoint
    var product: SuggestionProduct?
}

struct SuggestionProduct: Codable, Hashable {
    let id: String?
    let name: String?
    let price: Double?
    let imageUrl: String?
    let category: String?

    var displayImageURL: URL? {
        guard let img = imageUrl, !img.isEmpty else { return nil }
        return URL(string: AppConstants.API.imageBasePath + img)
    }
}

struct BudgetSnapshot: Codable, Hashable {
    var totalBudget: Double
    var spentAmount: Double
    var remainingAmount: Double
    var lastUpdated: String?

    /// Fill level 0.0 – 1.0 for piggy bank
    var fillLevel: Double {
        guard totalBudget > 0 else { return 0 }
        return min(1, max(0, remainingAmount / totalBudget))
    }

    static let zero = BudgetSnapshot(totalBudget: 0, spentAmount: 0, remainingAmount: 0)
}

struct EventDetails: Codable, Hashable {
    var aiPlannerAnswers: [String]?
    var targetBudget: Double?
    var paymentSplitType: SplitType?
}

struct GiftingDetails: Codable, Hashable {
    var collaboratorCount: Int?
    var aiPlannerAnswers: [String]?
    var splitType: SplitType?
    var creatorBudget: Double?
    var pooledBudget: Double?
    var budgetStatus: BudgetStatus?
}

// MARK: - Registry Model

struct RegistryModel: Codable, Identifiable, Hashable {
    var id: String { _id ?? UUID().uuidString }
    let _id: String?
    let adminId: String?
    var name: String
    let joinCode: String?
    let registryType: RegistryType?
    var creatorName: String?
    var eventType: EventType?
    var eventDate: String?
    var currency: CurrencyInfo?
    var eventDetails: EventDetails?
    var giftingDetails: GiftingDetails?
    var members: [RegistryMember]?
    var cartItems: [CartItemModel]?
    var aiSuggestions: [AiSuggestion]?
    var budgetSnapshot: BudgetSnapshot?
    let createdAt: String?

    var displayEventDate: String {
        guard let dateStr = eventDate else { return "No date set" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: dateStr) {
            let f = DateFormatter()
            f.dateFormat = "dd MMM yyyy"
            return f.string(from: date)
        }
        return dateStr
    }

    var memberCount: Int { members?.count ?? 0 }
    var cartItemCount: Int { cartItems?.count ?? 0 }

    var currencySymbol: String { currency?.symbol ?? "$" }
    var currencyCode: String { currency?.code ?? "USD" }
}

// MARK: - API Request Bodies

struct CreateRegistryRequest: Encodable {
    let name: String
    let registryType: String
    let creatorName: String
    let eventType: String
    let eventDate: String?
    let currency: CurrencyInfo
    let eventDetails: EventDetailsRequest?
    let giftingDetails: GiftingDetailsRequest?
}

struct EventDetailsRequest: Encodable {
    let aiPlannerAnswers: [String]
    let targetBudget: Double
    let paymentSplitType: String
}

struct GiftingDetailsRequest: Encodable {
    let collaboratorCount: Int
    let aiPlannerAnswers: [String]
    let splitType: String
    let creatorBudget: Double
    let pooledBudget: Double
}

struct JoinRegistryRequest: Encodable {
    let joinCode: String
    let contributedBudget: Double?
}

struct AddCartItemRequest: Encodable {
    let productId: String
    let quantity: Int
    let price: Double
    let name: String
    let imageUrl: String?
    let source: String
}

// MARK: - API Response Wrappers

struct SuggestionsResponse: Decodable {
    let suggestions: [AiSuggestion]
}

struct MembersResponse: Decodable {
    let members: [RegistryMember]
}

struct CartUpdateResponse: Decodable {
    let cartItems: [CartItemModel]
    let budgetSnapshot: BudgetSnapshot
}
