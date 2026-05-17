//
//  OrdersView.swift
//  WSHackathonApp
//

import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()
    @Environment(UserManager.self) private var userManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: Int = 0 // 0 for My Orders, 1 for Past Orders
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Orders", selection: $selectedTab) {
                    Text("My Orders").tag(0)
                    Text("Past Orders").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if selectedTab == 0 {
                                if viewModel.myOrders.isEmpty {
                                    emptyState(title: "No Active Orders", message: "You have no ongoing orders.")
                                } else {
                                    ForEach(viewModel.myOrders) { order in
                                        NavigationLink(destination: OrderDetailView(order: order)) {
                                            OrderCard(order: order)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else {
                                if viewModel.pastOrders.isEmpty {
                                    emptyState(title: "No Past Orders", message: "You haven't made any purchases yet.")
                                } else {
                                    ForEach(viewModel.pastOrders) { order in
                                        NavigationLink(destination: OrderDetailView(order: order)) {
                                            OrderCard(order: order)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle("MY ORDERS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("MY ORDERS")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.primary)
            }
        }
        .task {
            if let userId = userManager.currentUser?.id {
                await viewModel.fetchOrders(userId: userId)
            }
        }
    }
    
    // Removed segmentButton as we are using native Picker
    
    private func emptyState(title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 80)
            
            ZStack {
                Circle()
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(width: 80, height: 80)
                Image(systemName: "shippingbox")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color(hex: "#D4AF37"))
            }
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.primary)
            
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color.secondary)
            
            Spacer()
        }
    }
}

struct OrderCard: View {
    let order: WSOrderWithItems
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: ID and Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ORDER-\(order.id.uuidString.prefix(8).uppercased())")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.primary)
                    
                    if let date = order.createdAt {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }
                }
                Spacer()
                
                Text(order.status.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "#1F6D26")) // Dark green text
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#D4F0CD")) // Light green background
                    .clipShape(Capsule())
            }
            
            Divider().padding(.vertical, 4)
            
            // Items Preview
            if let firstItem = order.orderItems.first {
                HStack(spacing: 16) {
                    // Image
                    if let imageUrlStr = firstItem.productImage, let url = URL(string: imageUrlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle().fill(Color(uiColor: .secondarySystemBackground))
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                Rectangle().fill(Color(uiColor: .secondarySystemBackground))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Rectangle()
                            .fill(Color(uiColor: .secondarySystemBackground))
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(firstItem.productName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .lineLimit(2)
                        
                        if order.orderItems.count > 1 {
                            Text("+\(order.orderItems.count - 1) more items")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.secondary)
                        } else {
                            Text("Qty: \(firstItem.quantity)")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                        Text(String(format: "$%.2f", order.totalAmount))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
