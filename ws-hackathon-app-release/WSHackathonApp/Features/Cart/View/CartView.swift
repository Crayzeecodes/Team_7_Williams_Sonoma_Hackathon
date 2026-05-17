//
//  CartView.swift
//  WSHackathonApp
//
//  Cart tab UI for Williams Sonoma shopping experience.
//

import SwiftUI

@available(iOS 18.0, *)
struct CartView: View {
    @Environment(WSCartManager.self) private var cartManager
    @Environment(NavigationManager.self) private var navManager
    @Environment(UserManager.self) private var userManager

    @State private var promoCode = ""
    @State private var showCheckout = false
    @State private var selectedProduct: WSProduct?
    @State private var recommendationProducts: [UUID: [WSProduct]] = [:]

    var body: some View {
        NavigationStack {
            Group {
                if cartManager.items.isEmpty {
                    emptyState
                } else {
                    cartContent
                }
            }
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(uiColor: .systemBackground))
            .safeAreaInset(edge: .bottom) {
                if !cartManager.items.isEmpty {
                    checkoutBar
                }
            }
            .navigationDestination(isPresented: $showCheckout) {
                CheckoutView(subtotal: cartManager.subtotal)
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product)
            }
            .task {
                if let userId = userManager.currentUser?.id {
                    await cartManager.loadCartIfNeeded(userId: userId)
                }
            }
            .task(id: cartRecommendationSignature) {
                await loadCartRecommendations()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Color.secondary)

            Text("Your cart is empty")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.primary)

            Text("Start adding cookware, bakeware, and kitchen essentials.")
                .font(.system(size: 15))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)

            WSPrimaryButton(title: "Continue Shopping") {
                navManager.selectedTab = .shop
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    private var cartContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(cartManager.items) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        CartItemCell(
                            item: item,
                            onUpdateQuantity: { newQuantity in
                                cartManager.updateQuantity(itemId: item.id, quantity: newQuantity)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProduct = item.product
                        }

                        if let suggestions = recommendationProducts[item.product.id], !suggestions.isEmpty {
                            CartBundleRecommendationSection(
                                products: suggestions,
                                onSelectProduct: { product in
                                    selectedProduct = product
                                },
                                onAddProduct: { product in
                                    cartManager.add(product: product)
                                }
                            )
                        }
                    }
                }

                promoSection
                summarySection
            }
            .padding(.top, 10)
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var promoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Promo Code")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.primary)

            HStack(spacing: 10) {
                TextField("Enter code", text: $promoCode)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .font(.system(size: 15))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Apply") { }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(promoCode.isEmpty ? Color.secondary : Color.white)
                    .frame(width: 76, height: 40)
                    .background(promoCode.isEmpty ? Color(uiColor: .systemGray4) : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(promoCode.isEmpty)
            }
        }
        .padding(14)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Summary")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.primary)

            SummaryRow(title: "Subtotal", value: formattedCurrency(cartManager.subtotal))
            SummaryRow(title: "Shipping", value: "Calculated at checkout")
            SummaryRow(title: "Estimated Tax", value: "Calculated at checkout")

            Divider()

            SummaryRow(title: "Total", value: formattedCurrency(cartManager.subtotal), isEmphasized: true)

            Text("Shipping and tax will be calculated at checkout.")
                .font(.system(size: 12))
                .foregroundStyle(Color.secondary)
        }
        .padding(14)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }

    private var checkoutBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Subtotal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Spacer()
                Text(formattedCurrency(cartManager.subtotal))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
            }

            WSPrimaryButton(title: "Checkout") {
                showCheckout = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color(uiColor: .separator)),
            alignment: .top
        )
    }

    private func formattedCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private var cartRecommendationSignature: String {
        cartManager.items
            .map { $0.product.id.uuidString }
            .sorted()
            .joined(separator: "|")
    }

    private func loadCartRecommendations() async {
        let items = cartManager.items
        let signature = cartRecommendationSignature

        guard !items.isEmpty else {
            recommendationProducts = [:]
            return
        }

        do {
            let catalog = try await WSService.shared.fetchProducts()
            let cartProducts = items.map(\.product)
            var nextRecommendations: [UUID: [WSProduct]] = [:]

            for item in items {
                let recommendations = await CartAIRecommendationService.shared.recommendations(
                    for: item.product,
                    cartProducts: cartProducts,
                    catalog: catalog,
                    limit: 4
                )
                nextRecommendations[item.product.id] = recommendations
            }

            if signature == cartRecommendationSignature {
                recommendationProducts = nextRecommendations
            }
        } catch {
            recommendationProducts = [:]
        }
    }
}

private struct CartItemCell: View {
    let item: WSCartItem
    let onUpdateQuantity: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                cartImage

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.product.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                        .layoutPriority(1)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    Text(primaryDetail)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("$\(item.lineTotal, specifier: "%.2f")")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.primary)

                        Text("$\(unitPrice, specifier: "%.2f") each")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.top, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack {
                    Spacer()
                    quantityControl
                }
                .frame(height: 116, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }

    private var unitPrice: Double {
        item.product.salePrice ?? item.product.price
    }

    private var primaryDetail: String {
        if let color = item.selectedColor, !color.isEmpty {
            return "Color: \(color)"
        }
        if let size = item.selectedSize, !size.isEmpty {
            return "Size: \(size)"
        }
        return item.product.category
    }

    private var cartImage: some View {
        ZStack {
            Rectangle()
                .fill(Color(uiColor: .secondarySystemBackground))

            if let imageURL = item.product.primaryImageURL {
                CustomAsyncImage(url: imageURL)
            } else if let assetName = item.product.imageNames.first, !assetName.hasPrefix("/") {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
        }
        .frame(width: 116, height: 116)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }

    private var quantityControl: some View {
        HStack(spacing: 8) {
            Button(action: { onUpdateQuantity(item.quantity - 1) }) {
                Image(systemName: item.quantity <= 1 ? "trash" : "minus")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 28, height: 28)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(Circle())
            }
            .foregroundStyle(item.quantity <= 1 ? Color.red : Color.primary)

            Text("\(item.quantity)")
                .font(.system(size: 14, weight: .semibold))
                .frame(minWidth: 22)

            Button(action: { onUpdateQuantity(item.quantity + 1) }) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 28, height: 28)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
        .foregroundStyle(Color.primary)
    }
}

private struct CartBundleRecommendationSection: View {
    let products: [WSProduct]
    let onSelectProduct: (WSProduct) -> Void
    let onAddProduct: (WSProduct) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("You'll need this")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(products) { product in
                        CartBundleProductCard(
                            product: product,
                            onSelect: {
                                onSelectProduct(product)
                            },
                            onAdd: {
                                onAddProduct(product)
                            }
                        )
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

private struct CartBundleProductCard: View {
    let product: WSProduct
    let onSelect: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 8) {
                    productImage

                    Text(product.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                        .frame(height: 34, alignment: .topLeading)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Text("$\(product.salePrice ?? product.price, specifier: "%.2f")")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color.black)
                        .foregroundStyle(Color.white)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Add \(product.name) to cart")
            }
        }
        .padding(10)
        .frame(width: 148, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }

    private var productImage: some View {
        ZStack {
            Rectangle()
                .fill(Color(uiColor: .secondarySystemBackground))

            if let imageURL = product.primaryImageURL {
                CustomAsyncImage(url: imageURL)
            } else if let assetName = product.imageNames.first, !assetName.hasPrefix("/") {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
        }
        .frame(width: 128, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }
}

@Observable
private final class CheckoutViewModel {
    var subtotal: Double
    var email: String = "chirag@example.com"
    var shippingMethod: String = "Standard (3-5 days)"
    var paymentMethod: String = "Apple Pay"

    init(subtotal: Double) {
        self.subtotal = subtotal
    }

    var total: Double {
        subtotal
    }
}

private struct CheckoutView: View {
    @Environment(WSCartManager.self) private var cartManager
    @Environment(UserManager.self) private var userManager
    @Environment(NavigationManager.self) private var navManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: CheckoutViewModel
    @State private var isPlacingOrder = false
    @State private var orderError: String? = nil
    @State private var showSuccess = false

    init(subtotal: Double) {
        _viewModel = State(initialValue: CheckoutViewModel(subtotal: subtotal))
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
                        SummaryRow(title: "Shipping", value: "Calculated at checkout")
                        SummaryRow(title: "Estimated Tax", value: "Calculated at checkout")
                        Divider()
                        SummaryRow(title: "Total", value: formattedCurrency(viewModel.total), isEmphasized: true)
                    }
                )

                WSPrimaryButton(title: isPlacingOrder ? "Placing..." : "Place Order") {
                    placeOrder()
                }
                .disabled(isPlacingOrder)
                
                if let error = orderError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showSuccess) {
            OrderSuccessView {
                dismiss() // close checkout
                navManager.selectedTab = .shop
                navManager.showProfile = true
                navManager.showOrders = true // route to orders view
            }
        }
    }

    private func placeOrder() {
        guard let userId = userManager.currentUser?.id else {
            orderError = "User not logged in."
            return
        }
        guard !cartManager.items.isEmpty else {
            orderError = "Cart is empty."
            return
        }

        isPlacingOrder = true
        orderError = nil

        let items = cartManager.items
        let total = viewModel.total

        Task {
            do {
                _ = try await WSOrderService.shared.placeOrder(
                    userId: userId,
                    cartItems: items,
                    totalAmount: total,
                    shippingAddress: ["address": "123 Market St, San Francisco, CA"],
                    paymentMethod: viewModel.paymentMethod
                )

                cartManager.clear()
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
