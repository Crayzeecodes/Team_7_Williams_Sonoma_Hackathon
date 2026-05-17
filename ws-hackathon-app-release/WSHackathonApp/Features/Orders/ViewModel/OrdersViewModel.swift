
import Foundation
import SwiftUI
import Combine

@MainActor
class OrdersViewModel: ObservableObject {
    @Published var myOrders: [WSOrderWithItems] = []
    @Published var pastOrders: [WSOrderWithItems] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func fetchOrders(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let allOrders = try await WSOrderService.shared.fetchOrders(userId: userId)

            myOrders = allOrders.filter { ["pending", "paid", "shipped"].contains($0.status) }
            pastOrders = allOrders.filter { ["delivered", "cancelled"].contains($0.status) }
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching orders: \(error)")
        }
        isLoading = false
    }
}
