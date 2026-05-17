//
//  WSCartService.swift
//  WSHackathonApp
//
//  Supabase cart service for loading and persisting cart items.
//

import Foundation

@MainActor
final class WSCartService {
    static let shared = WSCartService()

    private init() {}

    private let cartPath = "/rest/v1/carts"
    private let cartItemsPath = "/rest/v1/cart_items"

    private var headers: [String: String] {
        var base = APIConfig.defaultHeaders
        if let anonKey = UserDefaults.standard.string(forKey: "ws_supabase_anon_key"), !anonKey.isEmpty {
            base["apikey"] = anonKey
            if base["Authorization"] == nil {
                base["Authorization"] = "Bearer \(anonKey)"
            }
        }
        base["Accept"] = "application/json"
        return base
    }

    func fetchOrCreateCartId(userId: UUID) async throws -> UUID {
        if let existing = try await fetchCartId(userId: userId) {
            return existing
        }
        return try await createCart(userId: userId)
    }

    func fetchCartItems(cartId: UUID) async throws -> [WSCartItem] {
        let select = "id,quantity,product:products(id,sku_id,name,description,price,images,category,stars)"
        let endpoint = Endpoint(
            path: cartItemsPath,
            method: .get,
            headers: headers,
            queryParameters: [
                "cart_id": "eq.\(cartId.uuidString)",
                "select": select
            ]
        )

        let rows: [CartItemRow] = try await APIClient.shared.request(endpoint)
        return rows.compactMap { row in
            guard let product = row.product else { return nil }
            return WSCartItem(
                id: row.id,
                product: product.toWSProduct(),
                quantity: row.quantity,
                selectedColor: nil,
                selectedSize: nil,
                giftWrapped: false,
                giftMessage: nil
            )
        }
    }

    func upsertCartItem(cartId: UUID, productId: UUID, quantity: Int) async throws -> CartItemRow {
        let endpoint = Endpoint(
            path: cartItemsPath,
            method: .post,
            headers: upsertHeaders(),
            queryParameters: [
                "on_conflict": "cart_id,product_id"
            ]
        )

        let body = CartItemUpsertPayload(
            cartId: cartId,
            productId: productId,
            quantity: quantity
        )

        let response: [CartItemRow] = try await APIClient.shared.request(endpoint, body: body)
        guard let first = response.first else {
            throw CartServiceError.emptyResponse
        }
        return first
    }

    func upsertCartItems(cartId: UUID, items: [WSCartItem]) async throws {
        for item in items {
            _ = try await upsertCartItem(cartId: cartId, productId: item.product.id, quantity: item.quantity)
        }
    }

    func deleteCartItem(cartId: UUID, productId: UUID) async throws {
        let endpoint = Endpoint(
            path: cartItemsPath,
            method: .delete,
            headers: deleteHeaders(),
            queryParameters: [
                "cart_id": "eq.\(cartId.uuidString)",
                "product_id": "eq.\(productId.uuidString)"
            ]
        )

        let _: [CartItemRow] = try await APIClient.shared.request(endpoint)
    }

    func clearCart(cartId: UUID) async throws {
        let endpoint = Endpoint(
            path: cartItemsPath,
            method: .delete,
            headers: deleteHeaders(),
            queryParameters: [
                "cart_id": "eq.\(cartId.uuidString)"
            ]
        )

        let _: [CartItemRow] = try await APIClient.shared.request(endpoint)
    }

    private func fetchCartId(userId: UUID) async throws -> UUID? {
        let endpoint = Endpoint(
            path: cartPath,
            method: .get,
            headers: headers,
            queryParameters: [
                "user_id": "eq.\(userId.uuidString)",
                "select": "id"
            ]
        )

        let rows: [CartRow] = try await APIClient.shared.request(endpoint)
        return rows.first?.id
    }

    private func createCart(userId: UUID) async throws -> UUID {
        var createHeaders = headers
        createHeaders["Prefer"] = "return=representation"

        let endpoint = Endpoint(
            path: cartPath,
            method: .post,
            headers: createHeaders
        )

        let body = CartCreatePayload(userId: userId)
        let response: [CartRow] = try await APIClient.shared.request(endpoint, body: body)
        guard let first = response.first else {
            throw CartServiceError.emptyResponse
        }
        return first.id
    }

    private func upsertHeaders() -> [String: String] {
        var base = headers
        base["Prefer"] = "return=representation, resolution=merge-duplicates"
        return base
    }

    private func deleteHeaders() -> [String: String] {
        var base = headers
        base["Prefer"] = "return=representation"
        return base
    }
}

private struct CartCreatePayload: Encodable {
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

private struct CartItemUpsertPayload: Encodable {
    let cartId: UUID
    let productId: UUID
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case cartId = "cart_id"
        case productId = "product_id"
        case quantity
    }
}

private struct CartRow: Decodable {
    let id: UUID
}

struct CartItemRow: Decodable {
    let id: UUID
    let quantity: Int
    let product: ProductRow?
}

struct ProductRow: Decodable {  // Changed from private to internal
    let id: UUID
    let skuId: String
    let name: String
    let description: String?
    let price: Double
    let images: [String]?
    let category: String?
    let stars: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case skuId = "sku_id"
        case name
        case description
        case price
        case images
        case category
        case stars
    }

    func toWSProduct() -> WSProduct {
        WSProduct(
            id: id,
            name: name,
            brand: "Williams Sonoma",
            category: category ?? "General",
            subcategory: nil,
            price: price,
            salePrice: nil,
            imageNames: images ?? [],
            rating: stars ?? 0,
            reviewCount: 0,
            description: description ?? "",
            specs: [:],
            isOnSale: false,
            isFeatured: false,
            isNewArrival: false,
            occasions: [],
            collectionName: nil,
            stockCount: 0,
            giftPackagingAvailable: false,
            giftPackagingPrice: nil,
            colors: nil,
            sizes: nil,
            createdAt: Date()
        )
    }
}

private enum CartServiceError: Error {
    case emptyResponse
}
