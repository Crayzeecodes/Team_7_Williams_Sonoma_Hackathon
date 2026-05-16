//
//  OrdersView.swift
//  WSHackathonApp
//

import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()
    @State private var selectedFilter: OrderFilter = .current
    
    enum OrderFilter: String, CaseIterable {
        case current = "Current Orders"
        case past = "Past Orders"
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Order Filter", selection: $selectedFilter) {
                    ForEach(OrderFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Spacer()
                
                // Placeholder for order list
                Text(selectedFilter == .current ? "No current orders." : "No past orders.")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Orders")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    OrdersView()
}
