import SwiftUI

struct CheckoutView: View {
    @Environment(WSCartManager.self) private var cartManager
    @Environment(UserManager.self) private var userManager
    @Environment(NavigationManager.self) private var navManager
    @Environment(\.dismiss) private var dismiss

    let checkoutItems: [WSCartItem]
    let registryId: String?
    let subtotal: Double

    @State private var viewModel: CheckoutViewModel
    @State private var isPlacingOrder = false
    @State private var orderError: String? = nil
    @State private var showSuccess = false

    init(subtotal: Double, checkoutItems: [WSCartItem]? = nil, registryId: String? = nil) {
        self.subtotal = subtotal
        self.checkoutItems = checkoutItems ?? []
        self.registryId = registryId
        _viewModel = State(initialValue: CheckoutViewModel(subtotal: subtotal))
    }

    private var itemsToCheckout: [WSCartItem] {
        if !checkoutItems.isEmpty {
            return checkoutItems
        }
        return cartManager.items
    }

    private var checkoutShipping: Double {
        let items = itemsToCheckout
        guard !items.isEmpty else { return 0 }

        return items.reduce(0) { total, item in
            total + shippingCharge(for: item.product) * Double(item.quantity)
        }
    }

    private var checkoutEstimatedTax: Double {
        let items = itemsToCheckout
        guard !items.isEmpty else { return 0 }

        return items.reduce(0) { total, item in
            let itemSubtotal = item.lineTotal
            return total + itemSubtotal * taxRate(for: item.product)
        }
    }

    private var checkoutTotal: Double {
        viewModel.subtotal + checkoutShipping + checkoutEstimatedTax
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                checkoutSection(
                    title: "Contact",
                    content: {
                        SummaryRow(title: "Email", value: viewModel.email)
                    }
                )

                checkoutSection(
                    title: "Shipping",
                    content: {
                        SummaryRow(title: "Method", value: viewModel.shippingMethod)
                        SummaryRow(title: "Address", value: "123 Market St, San Francisco, CA")
                    }
                )

                checkoutSection(
                    title: "Payment",
                    content: {
                        SummaryRow(title: "Method", value: viewModel.paymentMethod)
                        SummaryRow(title: "Billing", value: "Same as shipping")
                    }
                )

                checkoutSection(
                    title: "Order Summary",
                    content: {
                        SummaryRow(title: "Subtotal", value: formattedCurrency(viewModel.subtotal))
                        SummaryRow(title: "Shipping", value: formattedCurrency(checkoutShipping))
                        SummaryRow(title: "Estimated Tax", value: formattedCurrency(checkoutEstimatedTax))
                        Divider()
                        SummaryRow(title: "Total", value: formattedCurrency(checkoutTotal), isEmphasized: true)
                    }
                )

                if let error = orderError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            SlidingCheckoutButton(title: "SLIDE TO PLACE ORDER") {
                placeOrder()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showSuccess) {
            OrderSuccessView(
                onViewOrders: {
                    dismiss()
                    navManager.selectedTab = .shop
                    navManager.showProfile = true
                    navManager.showOrders = true
                },
                onContinueShopping: {
                    dismiss()
                    if registryId != nil {
                        navManager.selectedTab = .shop
                    }
                }
            )
        }
    }

    private func placeOrder() {
        guard let userId = userManager.currentUser?.id else {
            orderError = "User not logged in."
            return
        }
        let items = itemsToCheckout
        guard !items.isEmpty else {
            orderError = "Cart is empty."
            return
        }

        isPlacingOrder = true
        orderError = nil

        let total = checkoutTotal

        Task {
            do {
                _ = try await WSOrderService.shared.placeOrder(
                    userId: userId,
                    cartItems: items,
                    totalAmount: total,
                    shippingAddress: ["address": "123 Market St, San Francisco, CA"],
                    paymentMethod: viewModel.paymentMethod
                )

                if let registryId = registryId {
                    _ = try? await RegistryService.shared.deleteRegistry(id: registryId)
                } else {
                    cartManager.clear()
                }

                showSuccess = true
            } catch {
                orderError = error.localizedDescription
            }
            isPlacingOrder = false
        }
    }

    private func checkoutSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.primary)

            content()
        }
        .padding(14)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }

    private func formattedCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private func shippingCharge(for product: WSProduct) -> Double {
        let value = stableProductSeed(for: product) % 450
        return round((4.95 + Double(value) / 100) * 100) / 100
    }

    private func taxRate(for product: WSProduct) -> Double {
        let value = stableProductSeed(for: product) % 175
        return 0.0725 + Double(value) / 10_000
    }

    private func stableProductSeed(for product: WSProduct) -> Int {
        product.id.uuidString.unicodeScalars.reduce(0) { seed, scalar in
            seed + Int(scalar.value)
        }
    }
}

private struct SummaryRow: View {
    let title: String
    let value: String
    var isEmphasized: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: isEmphasized ? 15 : 14, weight: isEmphasized ? .semibold : .regular))
                .foregroundStyle(Color.primary)
            Spacer()
            Text(value)
                .font(.system(size: isEmphasized ? 15 : 14, weight: isEmphasized ? .semibold : .regular))
                .foregroundStyle(Color.primary)
        }
    }
}
