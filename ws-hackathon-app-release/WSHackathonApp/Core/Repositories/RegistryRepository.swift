//
//  RegistryRepository.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Combine
import Foundation

@MainActor
final class RegistryRepository: ObservableObject {
    
    @Published var currentRegistry: RegistryModel?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // For the hackathon, we load the user's registries and pick the first one as active
        Task {
            await loadActiveRegistry()
        }
    }
    
    // MARK: - Active Registry
    var isActiveRegistry: Bool {
        currentRegistry != nil
    }
    
    func loadActiveRegistry() async {
        do {
            let registries = try await RegistryService.shared.loadAll()
            if let first = registries.first {
                self.currentRegistry = first
            }
        } catch {
            print("Failed to load registries for global state: \(error)")
        }
    }
    
    // MARK: - Add Product
    
    func addProduct(_ product: ProductItem) {
        guard let registry = currentRegistry else { return }
        
        Task {
            do {
                let response = try await RegistryService.shared.addToCart(
                    registryId: registry.id,
                    productId: product.id,
                    quantity: 1,
                    price: product.price ?? 0.0,
                    name: product.title,
                    imageUrl: product.path,
                    source: .manual
                )
                self.currentRegistry?.cartItems = response.cartItems
                self.currentRegistry?.budgetSnapshot = response.budgetSnapshot
            } catch {
                print("Failed to add product to registry: \(error)")
            }
        }
    }
    
    // MARK: - Remove Item
    
    func removeItem(_ productId: String) {
        guard let registry = currentRegistry,
              let item = registry.cartItems?.first(where: { $0.productId == productId }),
              let itemId = item._id else { return }
              
        Task {
            do {
                let response = try await RegistryService.shared.removeFromCart(
                    registryId: registry.id,
                    itemId: itemId
                )
                self.currentRegistry?.cartItems = response.cartItems
                self.currentRegistry?.budgetSnapshot = response.budgetSnapshot
            } catch {
                print("Failed to remove product from registry: \(error)")
            }
        }
    }
    
    // MARK: - Quantity
    
    func quantity(for product: ProductItem) -> Int {
        currentRegistry?.cartItems?.first(where: { $0.productId == product.id })?.quantity ?? 0
    }
}
