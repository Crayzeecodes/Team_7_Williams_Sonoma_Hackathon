//
//  RegistryService.swift
//  WSHackathonApp
//

import Foundation
import Supabase

enum RegistryServiceError: LocalizedError {
    case invalidResponse
    case serverError(String)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .serverError(let message):
            return message
        case .notAuthenticated:
            return "Please log in to continue."
        }
    }
}

final class RegistryService {
    static let shared = RegistryService()
    private let aiSuggestionService = RegistryAISuggestionService.shared

    private init() {}

    // MARK: - Load all registries for the current user
    func loadRegistries() async throws -> [Registry] {
        guard let session = try? await supabase.auth.session else {
            throw RegistryServiceError.notAuthenticated
        }
        return try await supabase
            .from("registries")
            .select()
            .eq("admin_id", value: session.user.id.uuidString)
            .execute()
            .value
    }

    // MARK: - Preview a registry by join code (no auth required)
    func previewRegistry(joinCode: String) async throws -> RegistryPreview {
        let previews: [RegistryPreview] = try await supabase
            .from("registries")
            .select()
            .eq("join_code", value: joinCode)
            .execute()
            .value

        guard let preview = previews.first else {
            throw RegistryServiceError.serverError("Registry not found for code: \(joinCode)")
        }
        return preview
    }

    // MARK: - Create a registry
    func createRegistry(_ requestBody: CreateRegistryRequest) async throws -> Registry {
        let registry: Registry = try await supabase
            .from("registries")
            .insert(requestBody)
            .select()
            .single()
            .execute()
            .value

        guard let registryId = registry.supabaseId else {
            throw RegistryServiceError.invalidResponse
        }

        // Insert the creator as admin in registry_members
        let memberRequest = RegistryMemberRequest(
            registryId: registryId,
            userId: requestBody.adminId,
            role: .admin,
            contributedBudget: 0,
            joinedAt: Date()
        )

        try await supabase
            .from("registry_members")
            .insert(memberRequest)
            .execute()

        return registry
    }

    // MARK: - Join a registry
    func joinRegistry(code: String, contributedBudget: Double?) async throws -> Registry {
        guard let session = try? await supabase.auth.session else {
            throw RegistryServiceError.notAuthenticated
        }

        let preview = try await previewRegistry(joinCode: code)
        guard let registryId = preview.supabaseId else {
            throw RegistryServiceError.invalidResponse
        }

        let memberRequest = RegistryMemberRequest(
            registryId: registryId,
            userId: session.user.id.uuidString,
            role: .collaborator,
            contributedBudget: contributedBudget ?? 0,
            joinedAt: Date()
        )

        try await supabase
            .from("registry_members")
            .insert(memberRequest)
            .execute()

        return try await loadRegistry(id: registryId)
    }

    // MARK: - Load a single registry by ID
    func loadRegistry(id: String) async throws -> Registry {
        let registries: [Registry] = try await supabase
            .from("registries")
            .select()
            .eq("id", value: id)
            .execute()
            .value

        guard let registry = registries.first else {
            throw RegistryServiceError.serverError("Registry not found")
        }
        return registry
    }

    // MARK: - Leave a registry
    func leaveRegistry(id: String) async throws -> LeaveRegistryResponse {
        guard let session = try? await supabase.auth.session else {
            throw RegistryServiceError.notAuthenticated
        }

        try await supabase
            .from("registry_members")
            .delete()
            .eq("registry_id", value: id)
            .eq("user_id", value: session.user.id.uuidString)
            .execute()

        return LeaveRegistryResponse(deleted: true, registryId: id, registry: nil)
    }

    // MARK: - Cart item ops (stored as JSONB in registries.cart_items)
    func addCartItem(registryId: String, requestBody: AddRegistryCartItemRequest) async throws -> CartUpdatePayload {
        guard let session = try? await supabase.auth.session else {
            throw RegistryServiceError.notAuthenticated
        }

        let registry = try await loadRegistry(id: registryId)
        let userId = session.user.id.uuidString
        let quantity = max(1, requestBody.quantity)
        let price = requestBody.price ?? 0
        let productName = requestBody.name ?? "Registry item"
        let productImage = requestBody.imageUrl ?? ""
        var updatedItems = registry.cartItems

        if let existingIndex = updatedItems.firstIndex(where: {
            $0.productId == requestBody.productId &&
            $0.addedByUserId == userId &&
            $0.status == .inCart
        }) {
            let existingItem = updatedItems[existingIndex]
            updatedItems[existingIndex] = RegistryCartItem(
                id: existingItem.id,
                productId: existingItem.productId,
                addedByUserId: existingItem.addedByUserId,
                quantity: existingItem.quantity + quantity,
                price: price,
                name: productName,
                imageUrl: productImage,
                source: requestBody.source,
                status: requestBody.status,
                addedAt: existingItem.addedAt
            )
        } else {
            updatedItems.append(
                RegistryCartItem(
                    id: UUID().uuidString,
                    productId: requestBody.productId,
                    addedByUserId: userId,
                    quantity: quantity,
                    price: price,
                    name: productName,
                    imageUrl: productImage,
                    source: requestBody.source,
                    status: requestBody.status,
                    addedAt: Date()
                )
            )
        }

        let budgetSnapshot = recalculateBudgetSnapshot(for: registry, cartItems: updatedItems)
        let updateBody = RegistryCartUpdateRequest(
            cartItems: updatedItems,
            budgetSnapshot: budgetSnapshot,
            updatedAt: Date()
        )

        try await supabase
            .from("registries")
            .update(updateBody)
            .eq("id", value: registryId)
            .execute()

        return CartUpdatePayload(
            registryId: registryId,
            cartItems: updatedItems,
            budgetSnapshot: budgetSnapshot
        )
    }

    func removeCartItem(registryId: String, itemId: String) async throws -> CartUpdatePayload {
        throw RegistryServiceError.serverError("Cart item operations require a Supabase RPC function.")
    }

    // MARK: - AI suggestions
    func refreshSuggestions(registryId: String, forceRefresh: Bool) async throws -> [RegistryAISuggestion] {
        let registry = try await loadRegistry(id: registryId)

        if !forceRefresh, !registry.aiSuggestions.isEmpty {
            return registry.aiSuggestions
        }

        let allProducts = try await fetchAllProducts()
        let suggestedProductIDs = try await aiSuggestionService.suggestProductIDs(
            for: registry,
            products: allProducts
        )

        let suggestions = suggestedProductIDs.enumerated().map { index, productId in
            RegistryAISuggestion(
                productId: productId,
                score: max(0.1, 1 - (Double(index) * 0.08)),
                reasoning: "",
                generatedAt: Date()
            )
        }

        try await supabase
            .from("registries")
            .update(["ai_suggestions": suggestions])
            .eq("id", value: registryId)
            .execute()

        return suggestions
    }

    func loadSuggestedProducts(registryId: String, forceRefresh: Bool) async throws -> [RegistryProduct] {
        let suggestions = try await refreshSuggestions(registryId: registryId, forceRefresh: forceRefresh)
        return try await loadProducts(productIDs: suggestions.map(\.productId))
    }

    // MARK: - Load members from registry_members table
    func loadMembers(registryId: String) async throws -> [RegistryMemberDisplay] {
        return try await supabase
            .from("registry_members")
            .select()
            .eq("registry_id", value: registryId)
            .execute()
            .value
    }

    func loadProducts(productIDs: [String]) async throws -> [RegistryProduct] {
        guard !productIDs.isEmpty else { return [] }

        let idOrder = Dictionary(uniqueKeysWithValues: productIDs.enumerated().map { ($1, $0) })
        let products: [RegistryProduct] = try await supabase
            .from("products")
            .select()
            .in("id", values: productIDs)
            .execute()
            .value

        return products
            .sorted { lhs, rhs in
                let lhsIndex = idOrder[lhs.supabaseId ?? ""] ?? .max
                let rhsIndex = idOrder[rhs.supabaseId ?? ""] ?? .max
                return lhsIndex < rhsIndex
            }
    }

    private func fetchAllProducts() async throws -> [RegistryProduct] {
        try await supabase
            .from("products")
            .select()
            .execute()
            .value
    }

    private func recalculateBudgetSnapshot(
        for registry: Registry,
        cartItems: [RegistryCartItem]
    ) -> RegistryBudgetSnapshot {
        let totalBudget: Double
        if registry.registryType == .event {
            totalBudget = registry.eventDetails.targetBudget
        } else if registry.giftingDetails.splitType == .dutch {
            totalBudget = registry.giftingDetails.pooledBudget
        } else {
            totalBudget = registry.giftingDetails.creatorBudget
        }

        let spentAmount = cartItems.reduce(0) { partialResult, item in
            guard item.status == .inCart else { return partialResult }
            return partialResult + (item.price * Double(item.quantity))
        }

        return RegistryBudgetSnapshot(
            totalBudget: totalBudget,
            spentAmount: spentAmount,
            remainingAmount: max(0, totalBudget - spentAmount),
            lastUpdated: Date()
        )
    }
}

private struct RegistryCartUpdateRequest: Encodable {
    let cartItems: [RegistryCartItem]
    let budgetSnapshot: RegistryBudgetSnapshot
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case cartItems = "cart_items"
        case budgetSnapshot = "budget_snapshot"
        case updatedAt = "updated_at"
    }
}

struct LeaveRegistryResponse: Codable {
    let deleted: Bool
    let registryId: String?
    let registry: Registry?
}
