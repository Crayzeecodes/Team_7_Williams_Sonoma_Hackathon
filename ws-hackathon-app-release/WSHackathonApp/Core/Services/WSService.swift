//
//  WSService.swift
//  WSHackathonApp
//
//  Fetches data from Supabase using the shared SDK client.
//

import Foundation
import CryptoKit
import Supabase

// MARK: - Internal DTO matching public.products table exactly
private struct SupabaseProduct: Decodable {
    let id: String
    let skuId: String?
    let name: String
    let description: String?
    let price: Double
    let images: [String]?
    let category: String?
    let specs: [String]?
    let stars: Double?
    let arModelUrl: String?
    let arScale: Double?
    let arPlacementType: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case skuId = "sku_id"
        case name, description, price, images, category, specs, stars
        case arModelUrl = "ar_model_url"
        case arScale = "ar_scale"
        case arPlacementType = "ar_placement_type"
        case createdAt = "created_at"
    }
}

@MainActor
final class WSService {
    static let shared = WSService()

    private init() {}

    func fetchProducts() async throws -> [WSProduct] {
        let supabaseProducts: [SupabaseProduct] = try await supabase
            .from("products")
            .select()
            .execute()
            .value

        // Only mark these specific SKUs as deals
        let dealDiscounts: [String: Double] = [
            "FRN-CHAIR-003": 15,
            "FRN-CHAIR-002": 25,
            "FRN-CHAIR-001": 35,
            "ELC-MICRO-001": 40,
            "ELC-COFFEE-001": 55,
            "ELC-FRIDGE-001": 20
        ]

        return supabaseProducts.enumerated().map { index, product in
            let specs: [String: String] = (product.specs ?? []).reduce(into: [:]) { dict, spec in
                let parts = spec.split(separator: ":", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    dict[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
                }
            }

            // Use actual Supabase UUID instead of hashing, so cart foreign keys match
            let productUUID: UUID = UUID(uuidString: product.id) ?? Self.stableUUID(for: product.id)

            // Determine sale info for deal items
            let discountPercent = product.skuId.flatMap { dealDiscounts[$0] }
            let computedSalePrice: Double? = discountPercent.map { round(product.price * (1 - $0 / 100) * 100) / 100 }
            let onSale = discountPercent != nil

            return WSProduct(
                id: productUUID,
                name: product.name,
                brand: "Williams Sonoma",
                category: product.category ?? "General",
                subcategory: product.category ?? "General",
                price: product.price,
                salePrice: computedSalePrice,
                imageNames: product.images ?? [],
                rating: product.stars ?? 0,
                reviewCount: 12 + (index * 5),
                description: product.description ?? "",
                specs: specs,
                isOnSale: onSale,
                isFeatured: index < 8,
                isNewArrival: index % 3 == 0,
                occasions: Self.occasions(for: product.category ?? "General"),
                collectionName: "Williams Sonoma",
                stockCount: 25 + (index % 12) * 3,
                giftPackagingAvailable: true,
                giftPackagingPrice: 9.95,
                colors: nil,
                sizes: nil,
                createdAt: Self.parseDate(product.createdAt) ?? (Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date())
            )
        }
    }

    func fetchCategories() async throws -> [WSCategory] {
        let products = try await fetchProducts()
        let grouped = Dictionary(grouping: products, by: \.category)
        return grouped.keys.sorted().enumerated().map { index, category in
            WSCategory(
                id: index + 1,
                name: category,
                icon: Self.iconName(for: category),
                productCount: grouped[category]?.count ?? 0,
                imageAsset: nil
            )
        }
    }

    func fetchRecommendations(userId: UUID? = nil) async throws -> [WSProduct] {
        let products = try await fetchProducts()
        return Array(products.sorted { lhs, rhs in
            if lhs.isFeatured != rhs.isFeatured {
                return lhs.isFeatured && !rhs.isFeatured
            }
            return lhs.rating > rhs.rating
        }.prefix(8))
    }

    func fetchDeals() async throws -> [WSDeal] {
        let products = try await fetchProducts()
        return products
            .filter(\.isOnSale)
            .map { product in
                WSDeal(
                    id: UUID(),
                    product: product,
                    discountType: "percentage",
                    discountValue: product.salePrice != nil
                        ? round((1 - product.salePrice! / product.price) * 100)
                        : 15,
                    validUntil: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                    couponCode: nil
                )
            }
    }

    func fetchOccasions() async throws -> [WSOccasion] {
        return MockData.occasions
    }

    func fetchCollections() async throws -> [WSCollection] {
        return MockData.collections
    }

    func fetchProductDetail(id: UUID) async throws -> WSProduct? {
        let products = try await fetchProducts()
        return products.first { $0.id == id }
    }

    func fetchReviews(productId: UUID) async throws -> [WSReview] {
        return MockData.reviews.filter { $0.productId == productId }
    }

    func submitReview(_ review: WSReview) async throws {
        print("Review submitted: \(review)")
    }

    func addToCart(productId: UUID, quantity: Int, color: String?, size: String?, giftWrapped: Bool) async throws {
        // POST to Supabase cart_items table in production
    }

    func addToRegistry(productId: UUID) async throws {
        // POST to Supabase registry table in production
    }
}

private extension WSService {
    static func stableUUID(for rawValue: String) -> UUID {
        let digest = SHA256.hash(data: Data(rawValue.utf8))
        let bytes = Array(digest.prefix(16))
        let uuid = uuid_t(bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                          bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15])
        return UUID(uuid: uuid)
    }

    static func iconName(for category: String) -> String {
        let normalized = category.lowercased()
        if normalized.contains("cookware") { return "flame" }
        if normalized.contains("knife") || normalized.contains("cutlery") { return "scissors" }
        if normalized.contains("bake") { return "birthday.cake" }
        if normalized.contains("electric") { return "bolt.circle" }
        if normalized.contains("coffee") || normalized.contains("tea") { return "cup.and.saucer" }
        if normalized.contains("food") { return "bag" }
        return "fork.knife"
    }

    static func occasions(for category: String) -> [String] {
        switch category.lowercased() {
        case let value where value.contains("cookware"):
            return ["Housewarming Gifts", "Wedding Registry"]
        case let value where value.contains("bake"):
            return ["Holiday Entertaining"]
        case let value where value.contains("coffee"):
            return ["Morning Rituals"]
        default:
            return ["Everyday Cooking"]
        }
    }

    static func parseDate(_ rawValue: String?) -> Date? {
        guard let rawValue, !rawValue.isEmpty else { return nil }
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = iso8601.date(from: rawValue) {
            return parsed
        }

        let fallback = ISO8601DateFormatter()
        return fallback.date(from: rawValue)
    }
}
