
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
    private let joinedRegistryIDsKeyPrefix = "ws.joinedRegistryIDs."

    private init() {}

    func loadRegistries() async throws -> [Registry] {
        guard let session = try? await supabase.auth.session else {
            throw RegistryServiceError.notAuthenticated
        }

        let userId = session.user.id.uuidString.lowercased()
        let ownedRegistries: [Registry] = try await supabase
            .from("registries")
            .select()
            .eq("admin_id", value: userId)
            .execute()
            .value

        let memberships: [RegistryMemberRequest] = try await supabase
            .from("registry_members")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        var joinedRegistryIDs = Set(memberships.map(\.registryId))
        joinedRegistryIDs.formUnion(cachedJoinedRegistryIDs(for: userId))

        let ownedRegistryIDs = Set(ownedRegistries.map { $0.supabaseId ?? $0.id })
        joinedRegistryIDs.subtract(ownedRegistryIDs)

        let joinedRegistries = try await loadJoinedRegistries(ids: joinedRegistryIDs, userId: userId)

        return uniqueSortedRegistries(ownedRegistries + joinedRegistries)
    }

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

    func joinRegistry(code: String, contributedBudget: Double?) async throws -> Registry {
        guard let session = try? await supabase.auth.session else {
            throw RegistryServiceError.notAuthenticated
        }

        let preview = try await previewRegistry(joinCode: code)
        guard let registryId = preview.supabaseId else {
            throw RegistryServiceError.invalidResponse
        }

        let existingMemberships: [RegistryMemberRequest] = try await supabase
            .from("registry_members")
            .select()
            .eq("registry_id", value: registryId)
            .eq("user_id", value: session.user.id.uuidString.lowercased())
            .execute()
            .value

        if !existingMemberships.isEmpty {
            cacheJoinedRegistry(id: registryId, for: session.user.id.uuidString.lowercased())
            return try await loadRegistry(id: registryId)
        }

        let memberRequest = RegistryMemberRequest(
            registryId: registryId,
            userId: session.user.id.uuidString.lowercased(),
            role: .collaborator,
            contributedBudget: contributedBudget ?? 0,
            joinedAt: Date()
        )

        do {
            try await supabase
                .from("registry_members")
                .insert(memberRequest)
                .execute()
        } catch {
            // If this user is already a member (duplicate key / unique constraint),
            // just return the existing registry instead of surfacing a DB error.
            let msg = error.localizedDescription.lowercased()
            if msg.contains("duplicate key") || msg.contains("23505") || msg.contains("unique constraint") {
                cacheJoinedRegistry(id: registryId, for: session.user.id.uuidString.lowercased())
                return try await loadRegistry(id: registryId)
            }
            throw error
        }

        cacheJoinedRegistry(id: registryId, for: session.user.id.uuidString.lowercased())
        let registry = try await loadRegistry(id: registryId)
        if registry.registryType == .gifting,
           registry.giftingDetails.splitType == .dutch,
           contributedBudget != nil {
            return try await updateDutchBudgetAfterJoin(registry: registry, contribution: contributedBudget ?? 0)
        }

        return registry
    }

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

    func leaveRegistry(id: String) async throws -> LeaveRegistryResponse {
        guard let session = try? await supabase.auth.session else {
            throw RegistryServiceError.notAuthenticated
        }

        let userId = session.user.id.uuidString.lowercased()

        let members: [RegistryMemberRequest] = try await supabase
            .from("registry_members")
            .select()
            .eq("registry_id", value: id)
            .eq("user_id", value: userId)
            .execute()
            .value

        guard let member = members.first else {
            return LeaveRegistryResponse(deleted: true, registryId: id, registry: nil)
        }

        try await supabase
            .from("registry_members")
            .delete()
            .eq("registry_id", value: id)
            .eq("user_id", value: userId)
            .execute()

        removeCachedJoinedRegistry(id: id, for: userId)

        let registry = try? await loadRegistry(id: id)
        if let registry = registry,
           registry.registryType == .gifting,
           registry.giftingDetails.splitType == .dutch {
            let updatedGiftingDetails = RegistryGiftingDetails(
                collaboratorCount: registry.giftingDetails.collaboratorCount,
                aiPlannerAnswers: registry.giftingDetails.aiPlannerAnswers,
                splitType: registry.giftingDetails.splitType,
                creatorBudget: registry.giftingDetails.creatorBudget,
                pooledBudget: max(0, registry.giftingDetails.pooledBudget - member.contributedBudget),
                budgetStatus: registry.giftingDetails.budgetStatus
            )

            let spent = registry.cartItems
                .filter { $0.status == .inCart || $0.status == .purchased }
                .reduce(0) { $0 + ($1.price * Double($1.quantity)) }
            let updatedBudget = RegistryBudgetSnapshot(
                totalBudget: updatedGiftingDetails.pooledBudget,
                spentAmount: spent,
                remainingAmount: max(0, updatedGiftingDetails.pooledBudget - spent),
                lastUpdated: Date()
            )

            try? await supabase
                .from("registries")
                .update(RegistryBudgetPatch(giftingDetails: updatedGiftingDetails, budgetSnapshot: updatedBudget))
                .eq("id", value: id)
                .execute()

            let finalRegistry = try? await loadRegistry(id: id)
            return LeaveRegistryResponse(deleted: true, registryId: id, registry: finalRegistry)
        }

        return LeaveRegistryResponse(deleted: true, registryId: id, registry: registry)
    }

    func deleteRegistry(id: String) async throws {
        try await supabase
            .from("registry_members")
            .delete()
            .eq("registry_id", value: id)
            .execute()

        try await supabase
            .from("registries")
            .delete()
            .eq("id", value: id)
            .execute()

        if let session = try? await supabase.auth.session {
            removeCachedJoinedRegistry(id: id, for: session.user.id.uuidString.lowercased())
        }
    }

    func addCartItem(registryId: String, requestBody: AddRegistryCartItemRequest) async throws -> CartUpdatePayload {
        guard let session = try? await supabase.auth.session else {
            throw RegistryServiceError.notAuthenticated
        }

        let registry = try await loadRegistry(id: registryId)
        let product = try await loadProducts(productIDs: [requestBody.productId]).first
        let userId = session.user.id.uuidString.lowercased()
        let quantity = max(1, requestBody.quantity)
        let price = requestBody.price ?? product?.price ?? 0
        let productName = requestBody.name ?? product?.name ?? "Registry item"
        let productImage = requestBody.imageUrl ?? product?.images.first ?? ""
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

        let updatedBudget = budgetSnapshot(for: registry, cartItems: updatedItems)

        try await supabase
            .from("registries")
            .update(RegistryCartPatch(cartItems: updatedItems, budgetSnapshot: updatedBudget))
            .eq("id", value: registryId)
            .execute()

        return CartUpdatePayload(registryId: registryId, cartItems: updatedItems, budgetSnapshot: updatedBudget)
    }

    func setCartItemQuantity(registryId: String, itemId: String, quantity: Int) async throws -> CartUpdatePayload {
        let registry = try await loadRegistry(id: registryId)
        let updatedItems = registry.cartItems.compactMap { item -> RegistryCartItem? in
            guard item.id == itemId else { return item }
            guard quantity > 0 else { return nil }
            return RegistryCartItem(
                id: item.id,
                productId: item.productId,
                addedByUserId: item.addedByUserId,
                quantity: quantity,
                price: item.price,
                name: item.name,
                imageUrl: item.imageUrl,
                source: item.source,
                status: item.status,
                addedAt: item.addedAt
            )
        }
        let updatedBudget = budgetSnapshot(for: registry, cartItems: updatedItems)

        try await supabase
            .from("registries")
            .update(RegistryCartPatch(cartItems: updatedItems, budgetSnapshot: updatedBudget))
            .eq("id", value: registryId)
            .execute()

        return CartUpdatePayload(registryId: registryId, cartItems: updatedItems, budgetSnapshot: updatedBudget)
    }

    func removeCartItem(registryId: String, itemId: String) async throws -> CartUpdatePayload {
        let registry = try await loadRegistry(id: registryId)
        let updatedItems = registry.cartItems.filter { $0.id != itemId }
        let updatedBudget = budgetSnapshot(for: registry, cartItems: updatedItems)

        try await supabase
            .from("registries")
            .update(RegistryCartPatch(cartItems: updatedItems, budgetSnapshot: updatedBudget))
            .eq("id", value: registryId)
            .execute()

        return CartUpdatePayload(registryId: registryId, cartItems: updatedItems, budgetSnapshot: updatedBudget)
    }

    func clearCart(registryId: String) async throws -> CartUpdatePayload {
        let registry = try await loadRegistry(id: registryId)
        let updatedItems: [RegistryCartItem] = []
        let updatedBudget = budgetSnapshot(for: registry, cartItems: updatedItems)

        try await supabase
            .from("registries")
            .update(RegistryCartPatch(cartItems: updatedItems, budgetSnapshot: updatedBudget))
            .eq("id", value: registryId)
            .execute()

        return CartUpdatePayload(registryId: registryId, cartItems: updatedItems, budgetSnapshot: updatedBudget)
    }

    func createPoll(registryId: String) async throws -> Registry {
        let registry = try await loadRegistry(id: registryId)
        guard registry.registryType == .gifting else { return registry }
        guard !registry.cartItems.isEmpty else {
            throw RegistryServiceError.serverError("Add products to the shared cart before creating a poll.")
        }
        guard registry.polls.isEmpty else {
            return registry
        }

        let poll = RegistryPoll(
            pollId: UUID().uuidString,
            question: "Which gift should we choose?",
            options: registry.cartItems.map {
                RegistryPollOption(productId: $0.productId, votes: [])
            },
            status: .active,
            createdAt: Date()
        )
        let updatedPolls = [poll] + registry.polls

        try await supabase
            .from("registries")
            .update(RegistryPollsPatch(polls: updatedPolls))
            .eq("id", value: registryId)
            .execute()

        return try await loadRegistry(id: registryId)
    }

    func addProductToPoll(registryId: String, pollId: String, productId: String) async throws -> Registry {
        let registry = try await loadRegistry(id: registryId)
        let updatedPolls = registry.polls.map { poll in
            guard poll.id == pollId else { return poll }
            guard !poll.options.contains(where: { $0.productId == productId }) else { return poll }
            return RegistryPoll(
                pollId: poll.pollId,
                question: poll.question,
                options: poll.options + [RegistryPollOption(productId: productId, votes: [])],
                status: poll.status,
                createdAt: poll.createdAt
            )
        }

        try await supabase
            .from("registries")
            .update(RegistryPollsPatch(polls: updatedPolls))
            .eq("id", value: registryId)
            .execute()

        return try await loadRegistry(id: registryId)
    }

    func voteInPoll(registryId: String, pollId: String, productId: String) async throws -> Registry {
        guard let session = try? await supabase.auth.session else {
            throw RegistryServiceError.notAuthenticated
        }

        let registry = try await loadRegistry(id: registryId)
        let currentUserId = session.user.id.uuidString.lowercased()
        let updatedPolls = registry.polls.map { poll in
            guard poll.id == pollId, poll.status == .active else { return poll }
            let options = poll.options.map { option in
                let votesWithoutUser = option.votes.filter { $0.userId != currentUserId }
                if option.productId == productId {
                    return RegistryPollOption(
                        productId: option.productId,
                        votes: votesWithoutUser + [RegistryPollVote(userId: currentUserId)]
                    )
                }
                return RegistryPollOption(productId: option.productId, votes: votesWithoutUser)
            }
            return RegistryPoll(
                pollId: poll.pollId,
                question: poll.question,
                options: options,
                status: poll.status,
                createdAt: poll.createdAt
            )
        }

        try await supabase
            .from("registries")
            .update(RegistryPollsPatch(polls: updatedPolls))
            .eq("id", value: registryId)
            .execute()

        return try await loadRegistry(id: registryId)
    }

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

    func updatePlannerAnswers(registryId: String, answers: [RegistryPlannerAnswer]) async throws -> Registry {
        let registry = try await loadRegistry(id: registryId)

        if registry.registryType == .event {
            let updatedEventDetails = RegistryEventDetails(
                aiPlannerAnswers: answers,
                targetBudget: registry.eventDetails.targetBudget,
                paymentSplitType: registry.eventDetails.paymentSplitType
            )

            try await supabase
                .from("registries")
                .update(RegistryEventDetailsPatch(eventDetails: updatedEventDetails, aiSuggestions: []))
                .eq("id", value: registryId)
                .execute()
        } else {
            let updatedGiftingDetails = RegistryGiftingDetails(
                collaboratorCount: registry.giftingDetails.collaboratorCount,
                aiPlannerAnswers: answers,
                splitType: registry.giftingDetails.splitType,
                creatorBudget: registry.giftingDetails.creatorBudget,
                pooledBudget: registry.giftingDetails.pooledBudget,
                budgetStatus: registry.giftingDetails.budgetStatus
            )

            try await supabase
                .from("registries")
                .update(RegistryGiftingDetailsPatch(giftingDetails: updatedGiftingDetails, aiSuggestions: []))
                .eq("id", value: registryId)
                .execute()
        }

        _ = try await refreshSuggestions(registryId: registryId, forceRefresh: true)
        return try await loadRegistry(id: registryId)
    }

    func loadMembers(registryId: String) async throws -> [RegistryMemberDisplay] {
        var members: [RegistryMemberDisplay] = try await supabase
            .from("registry_members")
            .select()
            .eq("registry_id", value: registryId)
            .execute()
            .value

        let userIDs = members.map(\.userId)
        guard !userIDs.isEmpty else { return members }

        let users: [RegistryMemberUser] = try await supabase
            .from("users")
            .select("id,name,email")
            .in("id", values: userIDs)
            .execute()
            .value

        let usersById = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
        members = members.map { member in
            var copy = member
            copy.name = usersById[member.userId]?.name
            copy.email = usersById[member.userId]?.email
            return copy
        }
        return members.sorted { lhs, rhs in
            if lhs.role != rhs.role { return lhs.role.rawValue < rhs.role.rawValue }
            return (lhs.joinedAt ?? .distantPast) < (rhs.joinedAt ?? .distantPast)
        }
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

    private func budgetSnapshot(for registry: Registry, cartItems: [RegistryCartItem]) -> RegistryBudgetSnapshot {
        let spent = cartItems
            .filter { $0.status == .inCart || $0.status == .purchased }
            .reduce(0) { $0 + ($1.price * Double($1.quantity)) }
        let configuredBudget: Double
        if registry.registryType == .event {
            configuredBudget = registry.eventDetails.targetBudget
        } else if registry.giftingDetails.splitType == .dutch {
            configuredBudget = registry.giftingDetails.pooledBudget
        } else {
            configuredBudget = registry.giftingDetails.creatorBudget
        }
        let total = configuredBudget
        return RegistryBudgetSnapshot(
            totalBudget: total,
            spentAmount: spent,
            remainingAmount: max(0, total - spent),
            lastUpdated: Date()
        )
    }

    private func updateDutchBudgetAfterJoin(registry: Registry, contribution: Double) async throws -> Registry {
        let updatedGiftingDetails = RegistryGiftingDetails(
            collaboratorCount: registry.giftingDetails.collaboratorCount,
            aiPlannerAnswers: registry.giftingDetails.aiPlannerAnswers,
            splitType: registry.giftingDetails.splitType,
            creatorBudget: registry.giftingDetails.creatorBudget,
            pooledBudget: registry.giftingDetails.pooledBudget + contribution,
            budgetStatus: registry.giftingDetails.budgetStatus
        )

        let spent = registry.cartItems
            .filter { $0.status == .inCart || $0.status == .purchased }
            .reduce(0) { $0 + ($1.price * Double($1.quantity)) }
        let updatedBudget = RegistryBudgetSnapshot(
            totalBudget: updatedGiftingDetails.pooledBudget,
            spentAmount: spent,
            remainingAmount: max(0, updatedGiftingDetails.pooledBudget - spent),
            lastUpdated: Date()
        )

        try await supabase
            .from("registries")
            .update(RegistryBudgetPatch(giftingDetails: updatedGiftingDetails, budgetSnapshot: updatedBudget))
            .eq("id", value: registry.id)
            .execute()

        return try await loadRegistry(id: registry.id)
    }

    private func loadJoinedRegistries(ids: Set<String>, userId: String) async throws -> [Registry] {
        guard !ids.isEmpty else { return [] }
        let requestedIDs = Array(ids)

        do {
            let registries: [Registry] = try await supabase
                .from("registries")
                .select()
                .in("id", values: requestedIDs)
                .execute()
                .value

            let loadedIDs = Set(registries.map { $0.supabaseId ?? $0.id })
            let missingIDs = ids.subtracting(loadedIDs)
            guard !missingIDs.isEmpty else { return registries }

            var recoveredRegistries = registries
            for id in missingIDs {
                do {
                    recoveredRegistries.append(try await loadRegistry(id: id))
                } catch {
                    removeCachedJoinedRegistry(id: id, for: userId)
                }
            }
            return recoveredRegistries
        } catch {
            var recoveredRegistries: [Registry] = []
            for id in requestedIDs {
                do {
                    recoveredRegistries.append(try await loadRegistry(id: id))
                } catch {
                    removeCachedJoinedRegistry(id: id, for: userId)
                }
            }

            guard !recoveredRegistries.isEmpty else { throw error }
            return recoveredRegistries
        }
    }

    private func uniqueSortedRegistries(_ registries: [Registry]) -> [Registry] {
        var seenIDs = Set<String>()
        return registries
            .filter { registry in
                seenIDs.insert(registry.supabaseId ?? registry.id).inserted
            }
            .sorted { $0.eventDate < $1.eventDate }
    }

    private func cachedJoinedRegistryIDs(for userId: String) -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: joinedRegistryIDsKey(for: userId)) ?? [])
    }

    private func cacheJoinedRegistry(id: String, for userId: String) {
        var ids = cachedJoinedRegistryIDs(for: userId)
        ids.insert(id)
        saveCachedJoinedRegistryIDs(ids, for: userId)
    }

    private func removeCachedJoinedRegistry(id: String, for userId: String) {
        var ids = cachedJoinedRegistryIDs(for: userId)
        ids.remove(id)
        saveCachedJoinedRegistryIDs(ids, for: userId)
    }

    private func saveCachedJoinedRegistryIDs(_ ids: Set<String>, for userId: String) {
        UserDefaults.standard.set(Array(ids).sorted(), forKey: joinedRegistryIDsKey(for: userId))
    }

    private func joinedRegistryIDsKey(for userId: String) -> String {
        "\(joinedRegistryIDsKeyPrefix)\(userId)"
    }
}

struct LeaveRegistryResponse: Codable {
    let deleted: Bool
    let registryId: String?
    let registry: Registry?
}

private struct RegistryCartPatch: Encodable {
    let cartItems: [RegistryCartItem]
    let budgetSnapshot: RegistryBudgetSnapshot

    enum CodingKeys: String, CodingKey {
        case cartItems = "cart_items"
        case budgetSnapshot = "budget_snapshot"
    }
}

private struct RegistryPollsPatch: Encodable {
    let polls: [RegistryPoll]
}

private struct RegistryBudgetPatch: Encodable {
    let giftingDetails: RegistryGiftingDetails
    let budgetSnapshot: RegistryBudgetSnapshot

    enum CodingKeys: String, CodingKey {
        case giftingDetails = "gifting_details"
        case budgetSnapshot = "budget_snapshot"
    }
}

private struct RegistryEventDetailsPatch: Encodable {
    let eventDetails: RegistryEventDetails
    let aiSuggestions: [RegistryAISuggestion]

    enum CodingKeys: String, CodingKey {
        case eventDetails = "event_details"
        case aiSuggestions = "ai_suggestions"
    }
}

private struct RegistryGiftingDetailsPatch: Encodable {
    let giftingDetails: RegistryGiftingDetails
    let aiSuggestions: [RegistryAISuggestion]

    enum CodingKeys: String, CodingKey {
        case giftingDetails = "gifting_details"
        case aiSuggestions = "ai_suggestions"
    }
}

private struct RegistryMemberUser: Decodable {
    let id: String
    let name: String?
    let email: String?
}
