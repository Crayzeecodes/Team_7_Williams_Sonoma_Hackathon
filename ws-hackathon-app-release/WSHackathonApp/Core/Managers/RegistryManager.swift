//
//  RegistryManager.swift
//  WSHackathonApp
//
//  Stub for Registry Manager.
//

import SwiftUI

@Observable class RegistryManager {
    var items: [WSRegistryItem] = []
    
    func addToRegistry(_ product: WSProduct, variant: WSProductColor?) {
        // MongoDB-ready: will POST to /api/registry endpoint
        let item = WSRegistryItem(product: product, variant: variant)
        items.append(item)
    }
}

struct WSRegistryItem: Identifiable, Codable {
    let id: UUID
    let product: WSProduct
    let variant: WSProductColor?
    var addedAt: Date
    
    init(id: UUID = UUID(), product: WSProduct, variant: WSProductColor?, addedAt: Date = Date()) {
        self.id = id
        self.product = product
        self.variant = variant
        self.addedAt = addedAt
    }
}
