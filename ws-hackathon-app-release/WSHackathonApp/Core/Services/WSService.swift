//
//  WSService.swift
//  WSHackathonApp
//
//  Static now, MongoDB/REST-ready structure.
//

import Foundation

@MainActor
final class WSService {
    static let shared = WSService()

    private init() {}

    func fetchProducts() async throws -> [WSProduct] {
        return MockData.products
    }

    func fetchCategories() async throws -> [WSCategory] {
        return MockData.categories
    }

    func fetchRecommendations(userId: UUID? = nil) async throws -> [WSProduct] {
        return MockData.recommendations
    }

    func fetchDeals() async throws -> [WSDeal] {
        return MockData.deals
    }

    func fetchOccasions() async throws -> [WSOccasion] {
        return MockData.occasions
    }

    func fetchCollections() async throws -> [WSCollection] {
        return MockData.collections
    }

    func fetchProductDetail(id: UUID) async throws -> WSProduct? {
        return MockData.products.first { $0.id == id }
    }

    func fetchReviews(productId: UUID) async throws -> [WSReview] {
        return MockData.reviews.filter { $0.productId == productId }
    }

    func submitReview(_ review: WSReview) async throws {
        print("Review submitted: \(review)")
    }

    func addToCart(productId: UUID, quantity: Int, color: String?, size: String?, giftWrapped: Bool) async throws {
        // POST to MongoDB cart collection in production
    }

    func addToRegistry(productId: UUID) async throws {
        // POST to MongoDB registry collection in production
    }
}
