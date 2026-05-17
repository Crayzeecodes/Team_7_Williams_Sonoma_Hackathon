//
//  OrdersView.swift
//  WSHackathonApp
//

import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()
    @Environment(UserManager.self) private var userManager

    @State private var selectedTab = 0

    private var displayedOrders: [WSOrderWithItems] {
        selectedTab == 0 ? viewModel.myOrders : viewModel.pastOrders
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                ordersFilter
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                if viewModel.isLoading {
                    loadingState
                } else if let errorMessage = viewModel.errorMessage {
                    errorState(message: errorMessage)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            sectionHeader

                            if displayedOrders.isEmpty {
                                emptyState(
                                    title: selectedTab == 0 ? "No Active Orders" : "No Past Orders",
                                    message: selectedTab == 0
                                        ? "You have no ongoing orders right now."
                                        : "You haven't placed any completed orders yet."
                                )
                            } else {
                                ForEach(displayedOrders) { order in
                                    NavigationLink(destination: OrderDetailView(order: order)) {
                                        OrderCard(order: order)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle("My Orders")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let userId = userManager.currentUser?.id {
                await viewModel.fetchOrders(userId: userId)
            }
        }
    }

    private var ordersFilter: some View {
        Picker("Orders", selection: $selectedTab) {
            Text("Upcoming").tag(0)
            Text("Past").tag(1)
        }
        .pickerStyle(.segmented)
    }

    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedTab == 0 ? "Active Orders" : "Order History")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.primary)

                Text(selectedTab == 0
                    ? "Track your recent purchases and current deliveries."
                    : "Review your completed and archived purchases.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.secondary)
            }

            Spacer()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text("Loading your orders...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Color.secondary)

            Text("We couldn't load your orders")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.primary)

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyState(title: String, message: String) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: 76, height: 76)

                Image(systemName: "shippingbox")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Color.primary)
            }

            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.primary)

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct OrderCard: View {
    let order: WSOrderWithItems

    private var orderTitle: String {
        "ORDER-\(order.id.uuidString.prefix(8).uppercased())"
    }

    private var statusColors: (text: Color, fill: Color) {
        switch order.status.lowercased() {
        case "paid", "delivered":
            return (Color(hex: "#1F6D26"), Color(hex: "#D4F0CD"))
        case "pending":
            return (Color(hex: "#7A4A00"), Color(hex: "#F8E4B6"))
        case "cancelled":
            return (Color(hex: "#8A1C1C"), Color(hex: "#F8D7DA"))
        default:
            return (Color.primary, Color(uiColor: .secondarySystemBackground))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(orderTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.primary)

                    if let date = order.createdAt {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 14))
                            .foregroundStyle(Color.secondary)
                    }
                }

                Spacer()

                Text(order.status.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(statusColors.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColors.fill)
                    .clipShape(Capsule())
            }

            Divider()

            if let firstItem = order.orderItems.first {
                HStack(spacing: 14) {
                    orderImage(for: firstItem)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(firstItem.productName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .lineLimit(2)

                        Text(order.orderItems.count > 1 ? "+\(order.orderItems.count - 1) more items" : "Qty: \(firstItem.quantity)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
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
        .wsCardStyle()
    }

    @ViewBuilder
    private func orderImage(for item: WSOrderItem) -> some View {
        if let imageUrlStr = item.productImage, let url = URL(string: imageUrlStr) {
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
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 25))
        } else {
            Rectangle()
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }
}
