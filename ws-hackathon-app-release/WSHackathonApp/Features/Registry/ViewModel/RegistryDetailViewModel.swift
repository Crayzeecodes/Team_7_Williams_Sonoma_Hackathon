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
    @Published var isSavingPlannerAnswers: Bool = false
    @Published var isPresentingCollaborators: Bool = false
    @Published var isPresentingPlannerEditor: Bool = false
    @Published var errorMessage: String?
    @Published var coinAnimationTrigger: Int = 0
    @Published var addingProductIDs: Set<String> = []
    @Published var selectedPollProductIDs: [String: String] = [:]

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

    var polls: [RegistryPoll] {
        registry?.polls ?? []
    }

    var activePoll: RegistryPoll? {
        polls.first
    }

    var plannerAnswers: [RegistryPlannerAnswer] {
        guard let registry else { return [] }
        return registry.registryType == .event
            ? registry.eventDetails.aiPlannerAnswers
            : registry.giftingDetails.aiPlannerAnswers
    }

    var pollAddableCartItems: [RegistryCartItem] {
        guard let activePoll else { return [] }
        let productIDs = Set(activePoll.options.map(\.productId))
        return cartItems.filter { !productIDs.contains($0.productId) }
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

    func savePlannerAnswers(_ answers: [RegistryPlannerAnswer]) async {
        isSavingPlannerAnswers = true
        defer { isSavingPlannerAnswers = false }

        do {
            let updatedRegistry = try await registryService.updatePlannerAnswers(
                registryId: registryID,
                answers: answers
            )
            let refreshedProducts = try await registryService.loadSuggestedProducts(
                registryId: registryID,
                forceRefresh: false
            )
            registry = updatedRegistry
            suggestedProducts = refreshedProducts
            isPresentingPlannerEditor = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addSuggestedProductToCart(_ product: RegistryProduct) async {
        addingProductIDs.insert(product.id)
        defer { addingProductIDs.remove(product.id) }

        do {
            let payload = try await registryService.addCartItem(
                registryId: registryID,
                requestBody: AddRegistryCartItemRequest(
                    productId: product.id,
                    quantity: 1,
                    price: product.price,
                    name: product.name,
                    imageUrl: product.images.first,
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

    func incrementCartItem(_ item: RegistryCartItem) async {
        do {
            let payload = try await registryService.setCartItemQuantity(
                registryId: registryID,
                itemId: item.id,
                quantity: item.quantity + 1
            )
            applyCartUpdate(payload)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decrementCartItem(_ item: RegistryCartItem) async {
        do {
            let payload = try await registryService.setCartItemQuantity(
                registryId: registryID,
                itemId: item.id,
                quantity: item.quantity - 1
            )
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

    func createPoll() async {
        do {
            registry = try await registryService.createPoll(registryId: registryID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addToPoll(_ item: RegistryCartItem) async {
        guard let activePoll else { return }
        do {
            registry = try await registryService.addProductToPoll(
                registryId: registryID,
                pollId: activePoll.id,
                productId: item.productId
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func vote(in poll: RegistryPoll, productId: String) async {
        selectedPollProductIDs[poll.id] = productId
        do {
            registry = try await registryService.voteInPoll(
                registryId: registryID,
                pollId: poll.id,
                productId: productId
            )
        } catch {
            errorMessage = error.localizedDescription
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
