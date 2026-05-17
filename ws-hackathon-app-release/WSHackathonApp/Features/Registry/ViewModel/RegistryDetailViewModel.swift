//
//  RegistryDetailViewModel.swift
//  WSHackathonApp
//

import Foundation
import Combine

@MainActor
final class RegistryDetailViewModel: ObservableObject {
    @Published var registry: Registry?
    @Published var members: [RegistryMemberDisplay] = []
    @Published var isLoading: Bool = false
    @Published var isPresentingCollaborators: Bool = false
    @Published var errorMessage: String?
    @Published var coinAnimationTrigger: Int = 0

    let registryID: String

    private let registryService: RegistryService
    private let socketService: SocketService

    init(registryID: String) {
        self.registryID = registryID
        self.registryService = .shared
        self.socketService = .shared
    }

    var suggestions: [RegistryAISuggestion] {
        registry?.aiSuggestions ?? []
    }

    var cartItems: [RegistryCartItem] {
        registry?.cartItems ?? []
    }

    var budgetSnapshot: RegistryBudgetSnapshot {
        registry?.budgetSnapshot ?? Registry.emptyBudgetSnapshot
    }

    var currencySymbol: String {
        registry?.currency.symbol ?? "$"
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let registryTask = registryService.loadRegistry(id: registryID)
            async let membersTask = registryService.loadMembers(registryId: registryID)
            let (loadedRegistry, loadedMembers) = try await (registryTask, membersTask)
            registry = loadedRegistry
            members = loadedMembers
            configureSocket()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshSuggestions() async {
        do {
            let refreshed = try await registryService.refreshSuggestions(registryId: registryID, forceRefresh: true)
            guard let registry else { return }
            self.registry = Registry(
                supabaseId: registry.supabaseId,
                adminId: registry.adminId,
                name: registry.name,
                joinCode: registry.joinCode,
                registryType: registry.registryType,
                creatorName: registry.creatorName,
                eventType: registry.eventType,
                eventDate: registry.eventDate,
                currency: registry.currency,
                eventDetails: registry.eventDetails,
                giftingDetails: registry.giftingDetails,
                members: registry.members,
                cartItems: registry.cartItems,
                aiSuggestions: refreshed,
                polls: registry.polls,
                budgetSnapshot: registry.budgetSnapshot,
                shippingAddress: registry.shippingAddress,
                createdAt: registry.createdAt
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addSuggestionToCart(_ suggestion: RegistryAISuggestion) async {
        let product = suggestion.productRef.product
        do {
            let payload = try await registryService.addCartItem(
                registryId: registryID,
                requestBody: AddRegistryCartItemRequest(
                    productId: suggestion.productId,
                    quantity: 1,
                    price: product?.price,
                    name: product?.name,
                    imageUrl: product?.images.first,
                    source: .ai,
                    status: .inCart
                )
            )
            applyCartUpdate(payload)
            coinAnimationTrigger += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeCartItem(_ item: RegistryCartItem) async {
        do {
            let payload = try await registryService.removeCartItem(registryId: registryID, itemId: item.id)
            applyCartUpdate(payload)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveRegistry() async -> Bool {
        do {
            let response = try await registryService.leaveRegistry(id: registryID)
            return response.deleted || response.registry != nil
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func disconnect() {
        socketService.disconnect()
    }

    private func configureSocket() {
        socketService.onCartUpdated { [weak self] payload in
            guard payload.registryId == self?.registryID else { return }
            self?.applyCartUpdate(payload)
            self?.coinAnimationTrigger += 1
        }

        socketService.onMemberChanged { [weak self] payload in
            guard payload.registryId == self?.registryID else { return }
            Task {
                await self?.reloadMembersAndRegistry()
            }
        }

        socketService.connect(registryId: registryID)
    }

    private func reloadMembersAndRegistry() async {
        do {
            async let registryTask = registryService.loadRegistry(id: registryID)
            async let membersTask = registryService.loadMembers(registryId: registryID)
            let (loadedRegistry, loadedMembers) = try await (registryTask, membersTask)
            registry = loadedRegistry
            members = loadedMembers
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyCartUpdate(_ payload: CartUpdatePayload) {
        guard let registry else { return }
        self.registry = Registry(
            supabaseId: registry.supabaseId,
            adminId: registry.adminId,
            name: registry.name,
            joinCode: registry.joinCode,
            registryType: registry.registryType,
            creatorName: registry.creatorName,
            eventType: registry.eventType,
            eventDate: registry.eventDate,
            currency: registry.currency,
            eventDetails: registry.eventDetails,
            giftingDetails: registry.giftingDetails,
            members: registry.members,
            cartItems: payload.cartItems,
            aiSuggestions: registry.aiSuggestions,
            polls: registry.polls,
            budgetSnapshot: payload.budgetSnapshot,
            shippingAddress: registry.shippingAddress,
            createdAt: registry.createdAt
        )
    }
}
