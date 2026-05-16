// RegistryDetailViewModel.swift
// WSHackathonApp

import Foundation
import Combine

@MainActor
final class RegistryDetailViewModel: ObservableObject {

    // MARK: - Published
    @Published var registry: RegistryModel
    @Published var aiSuggestions: [AiSuggestion] = []
    @Published var members: [RegistryMember] = []

    @Published var isLoadingDetail: Bool = false
    @Published var isLoadingSuggestions: Bool = false
    @Published var isDeletingItem: Bool = false
    @Published var error: String?

    @Published var showCollaboratorsSheet: Bool = false
    @Published var budgetAnimationTrigger: Bool = false

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private let socket = SocketService.shared

    // MARK: - Init

    init(registry: RegistryModel) {
        self.registry = registry
        self.members = registry.members ?? []
        self.aiSuggestions = registry.aiSuggestions ?? []
    }

    // MARK: - Computed

    var budgetSnapshot: BudgetSnapshot {
        registry.budgetSnapshot ?? .zero
    }

    var cartItems: [CartItemModel] {
        registry.cartItems ?? []
    }

    var currencySymbol: String { registry.currencySymbol }

    var joinCode: String { registry.joinCode ?? "------" }

    // MARK: - Load full detail

    func loadDetail() async {
        isLoadingDetail = true
        do {
            let updated = try await RegistryService.shared.loadDetail(id: registry.id)
            registry = updated
            members = updated.members ?? []
            aiSuggestions = updated.aiSuggestions ?? []
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingDetail = false
    }

    // MARK: - Fetch AI Suggestions

    func fetchSuggestions() async {
        isLoadingSuggestions = true
        do {
            let suggestions = try await RegistryService.shared.fetchSuggestions(registryId: registry.id)
            aiSuggestions = suggestions
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingSuggestions = false
    }

    // MARK: - Add to Cart (from AI suggestion)

    func addSuggestionToCart(_ suggestion: AiSuggestion) async {
        guard let product = suggestion.product else { return }
        do {
            let response = try await RegistryService.shared.addToCart(
                registryId: registry.id,
                productId: suggestion.productId,
                quantity: 1,
                price: product.price ?? 0,
                name: product.name ?? suggestion.productId,
                imageUrl: product.imageUrl,
                source: .ai
            )
            updateCart(response)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Remove Cart Item

    func removeCartItem(_ item: CartItemModel) async {
        guard let itemId = item._id else { return }
        isDeletingItem = true
        do {
            let response = try await RegistryService.shared.removeFromCart(
                registryId: registry.id,
                itemId: itemId
            )
            updateCart(response)
        } catch {
            self.error = error.localizedDescription
        }
        isDeletingItem = false
    }

    // MARK: - Socket connect

    func connectSocket() {
        socket.connect(registryId: registry.id)

        socket.onCartUpdated { [weak self] payload in
            guard let self else { return }
            if payload.registryId == self.registry.id {
                self.registry.cartItems = payload.cartItems
                self.registry.budgetSnapshot = payload.budgetSnapshot
                self.budgetAnimationTrigger.toggle()
            }
        }.store(in: &cancellables)

        socket.onMemberJoined { [weak self] payload in
            guard let self else { return }
            if payload.registryId == self.registry.id {
                self.members.append(payload.member)
            }
        }.store(in: &cancellables)

        socket.onMemberLeft { [weak self] payload in
            guard let self else { return }
            if payload.registryId == self.registry.id {
                self.members.removeAll { $0.userId == payload.userId }
            }
        }.store(in: &cancellables)
    }

    func disconnectSocket() {
        socket.disconnect()
        cancellables.removeAll()
    }

    // MARK: - Private helpers

    private func updateCart(_ response: CartUpdateResponse) {
        registry.cartItems = response.cartItems
        registry.budgetSnapshot = response.budgetSnapshot
        budgetAnimationTrigger.toggle()
    }
}
