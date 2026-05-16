//
//  WSProduct.swift
//  WSHackathonApp
//
//  Data models for Williams Sonoma products and related entities.
//

import Foundation
import SwiftUI

// MARK: - Product
struct WSProduct: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let brand: String
    let category: String
    let subcategory: String?
    let price: Double
    let salePrice: Double?
    let imageNames: [String]
    let rating: Double
    let reviewCount: Int
    let description: String
    let specs: [String: String]
    let isOnSale: Bool
    let isFeatured: Bool
    let isNewArrival: Bool
    let occasions: [String]
    let collectionName: String?
    let stockCount: Int
    let giftPackagingAvailable: Bool
    let giftPackagingPrice: Double?
    let colors: [WSProductColor]?
    let sizes: [String]?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, brand, category, subcategory, price
        case salePrice = "sale_price"
        case imageNames = "image_names"
        case rating
        case reviewCount = "review_count"
        case description, specs
        case isOnSale = "is_on_sale"
        case isFeatured = "is_featured"
        case isNewArrival = "is_new_arrival"
        case occasions
        case collectionName = "collection_name"
        case stockCount = "stock_count"
        case giftPackagingAvailable = "gift_packaging_available"
        case giftPackagingPrice = "gift_packaging_price"
        case colors, sizes
        case createdAt = "created_at"
    }
}

// MARK: - Product Color
struct WSProductColor: Codable, Hashable {
    let name: String
    let hex: String
}

// MARK: - Category
struct WSCategory: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let icon: String
    let productCount: Int
    let imageAsset: String?

    enum CodingKeys: String, CodingKey {
        case id, name, icon
        case productCount = "product_count"
        case imageAsset = "image_asset"
    }
}

// MARK: - Occasion
struct WSOccasion: Identifiable, Codable {
    let id: UUID
    let name: String
    let subtitle: String
    let backgroundColor: String
    let imageAsset: String?
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, subtitle
        case backgroundColor = "background_color"
        case imageAsset = "image_asset"
        case tags
    }
}

// MARK: - Collection
struct WSCollection: Identifiable, Codable {
    let id: UUID
    let name: String
    let brand: String
    let tagline: String
    let imageAsset: String?
    let productIds: [UUID]

    enum CodingKeys: String, CodingKey {
        case id, name, brand, tagline
        case imageAsset = "image_asset"
        case productIds = "product_ids"
    }
}

// MARK: - Deal
struct WSDeal: Identifiable, Codable {
    let id: UUID
    let product: WSProduct
    let discountType: String
    let discountValue: Double
    let validUntil: Date?
    let couponCode: String?

    enum CodingKeys: String, CodingKey {
        case id, product
        case discountType = "discount_type"
        case discountValue = "discount_value"
        case validUntil = "valid_until"
        case couponCode = "coupon_code"
    }

    var discountLabel: String {
        if discountType == "percentage" {
            return "\(Int(discountValue))% OFF"
        } else {
            return "$\(Int(discountValue)) OFF"
        }
    }

    var salePrice: Double {
        if discountType == "percentage" {
            return product.price * (1 - discountValue / 100)
        } else {
            return max(0, product.price - discountValue)
        }
    }
}

// MARK: - Review
struct WSReview: Identifiable, Codable {
    let id: UUID?
    let productId: UUID
    let userId: UUID
    let userName: String
    let rating: Int
    let comment: String?
    let createdAt: Date?
    let verifiedPurchase: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case userId = "user_id"
        case userName = "user_name"
        case rating, comment
        case createdAt = "created_at"
        case verifiedPurchase = "verified_purchase"
    }
}

// MARK: - User
struct WSUser: Codable {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let isKeyRewardsMember: Bool
    let rewardPoints: Int

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case isKeyRewardsMember = "is_key_rewards_member"
        case rewardPoints = "reward_points"
    }

    var initials: String {
        "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased()
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// MARK: - Cart Item (new WS-specific)
struct WSCartItem: Identifiable, Codable {
    let id: UUID
    let product: WSProduct
    var quantity: Int
    var selectedColor: String?
    var selectedSize: String?
    var giftWrapped: Bool
    var giftMessage: String?

    var lineTotal: Double {
        let unitPrice = product.salePrice ?? product.price
        var total = unitPrice * Double(quantity)
        if giftWrapped, let giftPrice = product.giftPackagingPrice {
            total += giftPrice * Double(quantity)
        }
        return total
    }
}

extension WSProduct {
    var primaryImageURL: URL? {
        guard let first = imageNames.first else { return nil }
        if first.hasPrefix("http") {
            return URL(string: first)
        }
        if first.hasPrefix("/") {
            return APIConfig.baseURL.appendingPathComponent(String(first.dropFirst()))
        }
        return nil
    }

    var productSpecs: [WSProductSpec] {
        specs.map { WSProductSpec(label: $0.key, value: $0.value) }
            .sorted { $0.label < $1.label }
    }
}
