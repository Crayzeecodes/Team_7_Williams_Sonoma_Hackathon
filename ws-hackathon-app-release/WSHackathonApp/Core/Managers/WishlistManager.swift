//
//  WishlistManager.swift
//  WSHackathonApp
//
//  Manages the user's wishlist of saved products.
//

import Foundation

@Observable
class WishlistManager {
    var items: [WSProduct] = []

    var count: Int { items.count }

    func toggle(product: WSProduct) {
        if let index = items.firstIndex(where: { $0.id == product.id }) {
            items.remove(at: index)
        } else {
            items.append(product)
        }
    }

    func isWishlisted(_ product: WSProduct) -> Bool {
        items.contains(where: { $0.id == product.id })
    }

    func remove(product: WSProduct) {
        items.removeAll(where: { $0.id == product.id })
    }
}
