//
//  OrdersViewModel.swift
//  WSHackathonApp
//

import Foundation
import Combine

@MainActor
class OrdersViewModel: ObservableObject {
    // We will fetch orders from MongoDB here later
    @Published var orders: [String] = []
    
    func fetchOrders(status: String) {
        // Placeholder API call
    }
}
