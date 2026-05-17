//
//  WSService.swift
//  WSHackathonApp
//
//  Static now, Supabase-ready structure.
//

import Foundation
import CryptoKit

@MainActor
final class WSService {
    static let shared = WSService()

    private init() {}

    func fetchProducts() async throws -> [WSProduct] {
        guard let url = URL(string: AppConstants.API.aiBaseURL + "/products") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode([WSProduct].self, from: data)
        } catch {
            print("❌ Shop Fetch Decoding Error: \(error)")
            if let str = String(data: data, encoding: .utf8) {
                print("❌ Raw JSON: \(str.prefix(500))...")
            }
            throw error
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
        // POST to Supabase cart table in production
    }

    func addToRegistry(productId: UUID) async throws {
        // POST to Supabase registry table in production
    }
}

private extension WSService {
    static func stableUUID(for rawValue: String) -> UUID {
        let digest = SHA256.hash(data: Data(rawValue.utf8))
        let bytes = Array(digest.prefix(16))
        let uuid = uuid_t(bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15])
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

    func request<T: Decodable>(path: String) async throws -> T {
        let endpoint = Endpoint(path: path, method: .get)
        return try await APIClient.shared.request(endpoint)
    }
}

private struct RemoteSKU: Decodable {
    let id: String
    let name: String
    let price: Price
    let properties: Properties
    let media: Media
    let availability: String
    let deliveryEstimate: String

    struct Price: Decodable {
        let regularPrice: Double
        let sellingPrice: Double
    }

    struct Properties: Decodable {
        let brand: String?
        let productType: String?
        let allProductTypes: String?

        var specsDictionary: [String: String] {
            var values: [String: String] = [:]
            if let productType {
                values["Category"] = productType.normalizedCategoryName
            }
            if let allProductTypes {
                values["Collection"] = allProductTypes
            }
            if let brand {
                values["Brand"] = brand.formattedBrandName
            }
            return values
        }
    }

    struct Media: Decodable {
        let images: [Image]

        struct Image: Decodable {
            let path: String
        }
    }
}

private extension String {
    var formattedBrandName: String {
        split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    var normalizedCategoryName: String {
        replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
