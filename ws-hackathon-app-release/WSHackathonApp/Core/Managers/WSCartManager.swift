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

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        items.reduce(0) { $0 + $1.lineTotal }
    }

    func add(product: WSProduct, quantity: Int = 1, color: String? = nil, size: String? = nil, giftWrapped: Bool = false, giftMessage: String? = nil) {
        if let index = items.firstIndex(where: {
            $0.product.id == product.id &&
            $0.selectedColor == color &&
            $0.selectedSize == size
        }) {
            items[index].quantity += quantity
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
    }

    func remove(itemId: UUID) {
        items.removeAll(where: { $0.id == itemId })
    }

    func updateQuantity(itemId: UUID, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        if quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index].quantity = quantity
        }
    }

    func clear() {
        items.removeAll()
    }
}
