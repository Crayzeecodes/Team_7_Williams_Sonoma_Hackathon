// RegistryService.swift
// WSHackathonApp
// Network service singleton — all registry API calls.

import Foundation
import Combine

@MainActor
final class RegistryService: ObservableObject {

    static let shared = RegistryService()
    private init() {}

    // MARK: - Endpoints

    private enum Paths {
        static let base = "/api/registry"
        static func detail(_ id: String) -> String { "\(base)/\(id)" }
        static func join() -> String { "\(base)/join" }
        static func leave(_ id: String) -> String { "\(base)/\(id)/leave" }
        static func cart(_ id: String) -> String { "\(base)/\(id)/cart" }
        static func cartItem(_ id: String, itemId: String) -> String { "\(base)/\(id)/cart/\(itemId)" }
        static func suggest(_ id: String) -> String { "\(base)/\(id)/suggest" }
        static func members(_ id: String) -> String { "\(base)/\(id)/members" }
    }

    // MARK: - Load All Registries

    func loadAll() async throws -> [RegistryModel] {
        let endpoint = Endpoint(path: Paths.base, method: .get)
        return try await APIClient.shared.request(endpoint)
    }

    // MARK: - Load Detail

    func loadDetail(id: String) async throws -> RegistryModel {
        let endpoint = Endpoint(path: Paths.detail(id), method: .get)
        return try await APIClient.shared.request(endpoint)
    }

    // MARK: - Create Registry

    func create(_ body: CreateRegistryRequest) async throws -> RegistryModel {
        let endpoint = Endpoint(path: Paths.base, method: .post)
        return try await APIClient.shared.request(endpoint, body: body)
    }

    // MARK: - Join Registry

    func join(code: String, contributedBudget: Double?) async throws -> RegistryModel {
        let body = JoinRegistryRequest(joinCode: code.uppercased(), contributedBudget: contributedBudget)
        let endpoint = Endpoint(path: Paths.join(), method: .post)
        return try await APIClient.shared.request(endpoint, body: body)
    }

    // MARK: - Leave Registry

    func leave(id: String) async throws {
        let endpoint = Endpoint(path: Paths.leave(id), method: .delete)
        let _: EmptyResponse = try await APIClient.shared.request(endpoint)
    }

    // MARK: - Add to Cart

    func addToCart(
        registryId: String,
        productId: String,
        quantity: Int,
        price: Double,
        name: String,
        imageUrl: String?,
        source: ItemSource
    ) async throws -> CartUpdateResponse {
        let body = AddCartItemRequest(
            productId: productId,
            quantity: quantity,
            price: price,
            name: name,
            imageUrl: imageUrl,
            source: source.rawValue
        )
        let endpoint = Endpoint(path: Paths.cart(registryId), method: .post)
        return try await APIClient.shared.request(endpoint, body: body)
    }

    // MARK: - Remove from Cart

    func removeFromCart(registryId: String, itemId: String) async throws -> CartUpdateResponse {
        let endpoint = Endpoint(path: Paths.cartItem(registryId, itemId: itemId), method: .delete)
        return try await APIClient.shared.request(endpoint)
    }

    // MARK: - Fetch AI Suggestions

    func fetchSuggestions(registryId: String) async throws -> [AiSuggestion] {
        let endpoint = Endpoint(path: Paths.suggest(registryId), method: .post)
        let response: SuggestionsResponse = try await APIClient.shared.request(endpoint)
        return response.suggestions
    }

    // MARK: - Fetch Members

    func fetchMembers(registryId: String) async throws -> [RegistryMember] {
        let endpoint = Endpoint(path: Paths.members(registryId), method: .get)
        let response: MembersResponse = try await APIClient.shared.request(endpoint)
        return response.members
    }
}

// MARK: - Empty response helper

private struct EmptyResponse: Decodable {}
