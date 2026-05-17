//
//  WSCartManager.swift
//  WSHackathonApp
//
//  Manages the shopping cart for Williams Sonoma products.
//

import Foundation

@Observable
class WSCartManager {
    var items: [WSCartItem] = []
    var isSyncing: Bool = false
    var lastSyncError: String?

    private let service = WSCartService.shared
    private var cartId: UUID?
    private var userId: UUID?
    private var hasLoadedRemote = false

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        items.reduce(0) { $0 + $1.lineTotal }
    }

    func loadCartIfNeeded(userId: UUID) async {
        if self.userId != userId {
            self.userId = userId
            self.cartId = nil
            self.hasLoadedRemote = false
        }
        guard !hasLoadedRemote else { return }
        await loadCart(userId: userId)
    }

    func add(product: WSProduct, quantity: Int = 1, color: String? = nil, size: String? = nil, giftWrapped: Bool = false, giftMessage: String? = nil) {
        let existingIndex = items.firstIndex(where: {
            $0.product.id == product.id &&
            $0.selectedColor == color &&
            $0.selectedSize == size
        })

        if let index = existingIndex {
            items[index].quantity = quantity
        } else {
            let item = WSCartItem(
                id: UUID(),
                product: product,
                quantity: quantity,
                selectedColor: color,
                selectedSize: size,
                giftWrapped: giftWrapped,
                giftMessage: giftMessage
            )
            items.append(item)
        }

        guard let userId else { return }
        let currentQuantity = items.first(where: { $0.product.id == product.id })?.quantity ?? quantity
        Task { await syncUpsert(productId: product.id, quantity: currentQuantity, userId: userId) }
    }

    func remove(itemId: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        let productId = items[index].product.id
        items.remove(at: index)

        guard let userId else { return }
        Task { await syncDelete(productId: productId, userId: userId) }
    }

    func updateQuantity(itemId: UUID, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }

        if quantity <= 0 {
            let productId = items[index].product.id
            items.remove(at: index)
            guard let userId else { return }
            Task { await syncDelete(productId: productId, userId: userId) }
        } else {
            items[index].quantity = quantity
            let productId = items[index].product.id
            guard let userId else { return }
            Task { await syncUpsert(productId: productId, quantity: quantity, userId: userId) }
        }
    }

    func clear() {
        items.removeAll()
        guard let userId else { return }
        Task { await syncClear(userId: userId) }
    }

    private func loadCart(userId: UUID) async {
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }

        do {
            let resolvedCartId = try await service.fetchOrCreateCartId(userId: userId)
            cartId = resolvedCartId
            let remoteItems = try await service.fetchCartItems(cartId: resolvedCartId)

            if remoteItems.isEmpty, !items.isEmpty {
                try await service.upsertCartItems(cartId: resolvedCartId, items: items)
                items = try await service.fetchCartItems(cartId: resolvedCartId)
            } else {
                items = remoteItems
            }
            hasLoadedRemote = true
        } catch {
            lastSyncError = error.localizedDescription
        }
    }

    private func syncUpsert(productId: UUID, quantity: Int, userId: UUID) async {
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }

        do {
            let resolvedCartId = try await service.fetchOrCreateCartId(userId: userId)
            cartId = resolvedCartId
            let row = try await service.upsertCartItem(cartId: resolvedCartId, productId: productId, quantity: quantity)
            if let index = items.firstIndex(where: { $0.product.id == productId }) {
                items[index].id = row.id
            }
        } catch {
            lastSyncError = error.localizedDescription
        }
    }

    private func syncDelete(productId: UUID, userId: UUID) async {
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }

        do {
            let resolvedCartId = try await service.fetchOrCreateCartId(userId: userId)
            cartId = resolvedCartId
            try await service.deleteCartItem(cartId: resolvedCartId, productId: productId)
        } catch {
            lastSyncError = error.localizedDescription
        }
    }

    private func syncClear(userId: UUID) async {
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }

        do {
            let resolvedCartId = try await service.fetchOrCreateCartId(userId: userId)
            cartId = resolvedCartId
            try await service.clearCart(cartId: resolvedCartId)
        } catch {
            lastSyncError = error.localizedDescription
        }
    }
}
