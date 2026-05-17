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
    @Published var suggestedProducts: [RegistryProduct] = []
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
            async let suggestedProductsTask = registryService.loadSuggestedProducts(registryId: registryID, forceRefresh: false)
            let (loadedRegistry, loadedMembers, loadedSuggestedProducts) = try await (registryTask, membersTask, suggestedProductsTask)
            registry = loadedRegistry
            members = loadedMembers
            suggestedProducts = loadedSuggestedProducts
            configureSocket()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshSuggestions() async {
        do {
            async let refreshedRegistry = registryService.loadRegistry(id: registryID)
            async let refreshedProducts = registryService.loadSuggestedProducts(registryId: registryID, forceRefresh: true)
            registry = try await refreshedRegistry
            suggestedProducts = try await refreshedProducts
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
            async let suggestedProductsTask = registryService.loadSuggestedProducts(registryId: registryID, forceRefresh: false)
            let (loadedRegistry, loadedMembers, loadedSuggestedProducts) = try await (registryTask, membersTask, suggestedProductsTask)
            registry = loadedRegistry
            members = loadedMembers
            suggestedProducts = loadedSuggestedProducts
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
