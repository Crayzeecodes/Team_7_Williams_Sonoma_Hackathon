
import SwiftUI
import UIKit

struct WSProductSpec: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

let exampleSpecs: [WSProductSpec] = [
    WSProductSpec(label: "Material", value: "Hard-Anodized Aluminum"),
    WSProductSpec(label: "Dimensions", value: "12\" × 8\" × 4\""),
    WSProductSpec(label: "Weight", value: "3.2 lbs"),
    WSProductSpec(label: "Dishwasher Safe", value: "Yes"),
    WSProductSpec(label: "Oven Safe", value: "Up to 400°F"),
    WSProductSpec(label: "Compatible Cooktops", value: "Gas, Electric, Induction"),
]

@available(iOS 18.0, *)
struct ProductDetailView: View {
    let product: WSProduct
    private let optionCardHeight: CGFloat = 82

    @Environment(WishlistManager.self) private var wishlistManager
    @Environment(WSCartManager.self) private var cartManager
    @Environment(NavigationManager.self) private var navManager
    @Environment(\.dismiss) private var dismiss

    @State private var registryManager = RegistryManager()
    @State private var selectedVariant: WSProductColor? = nil
    @State private var selectedSize: String? = nil
    @State private var giftPackaging: Bool = false
    @State private var isDescriptionExpanded: Bool = false
    @State private var isSpecsExpanded: Bool = false
    @State private var selectedImageIndex: Int = 0
    @State private var showARView = false
    @State private var showShareSheet = false
    @State private var showAddedToRegistryToast = false
    @State private var addedRegistryName = ""
    @State private var isWishlisted = false
    @State private var reviews: [WSReview] = []
    @State private var isAddedToCart = false
    @State private var showingRegistryPicker = false

    @State private var viewModel = ShopViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    imageCarousel
                    pageDots

                    productInfoBlock
                        .padding(.top, 32)

                    descriptionSection
                    viewInARButton
                    specsSection

                    if product.giftPackagingAvailable {
                        premiumPackagingCard
                    }

                    reviewsSection

                    relatedProductsSection
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(uiColor: .systemBackground))

            stickyBottomBar
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: { isWishlisted.toggle() }) {
                    Image(systemName: isWishlisted ? "heart.fill" : "heart")
                        .font(.system(size: 17))
                        .foregroundStyle(isWishlisted ? Color.red : Color.primary)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityLabel(isWishlisted ? "Remove from Wishlist" : "Add to Wishlist")

                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.primary)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Share product")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ProductShareSheet(activityItems: productShareItems)
        }
        .fullScreenCover(isPresented: $showARView) {
            ARProductView(product: product)
        }
        .onAppear {
            isWishlisted = wishlistManager.isWishlisted(product)
            selectedVariant = product.colors?.first
            selectedSize = product.sizes?.first
            reviews = MockData.reviews.filter { $0.productId == product.id }
            isAddedToCart = cartManager.items.contains(where: { $0.product.id == product.id })
            Task { await viewModel.loadData() }
        }
        .onChange(of: isWishlisted) { _, newValue in
            if newValue != wishlistManager.isWishlisted(product) {
                wishlistManager.toggle(product: product)
            }
        }
    }

    private var imageCarousel: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedImageIndex) {
                let count = max(1, product.imageNames.count)
                ForEach(0..<count, id: \.self) { index in
                    ZStack {
                        Color(uiColor: .secondarySystemBackground)
                        detailImage(for: index)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: UIScreen.main.bounds.height * 0.52)

        }
        .frame(height: UIScreen.main.bounds.height * 0.52)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            let count = max(1, product.imageNames.count)
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == selectedImageIndex ? Color.black : Color(uiColor: .tertiaryLabel))
                    .frame(width: i == selectedImageIndex ? 8 : 6, height: i == selectedImageIndex ? 8 : 6)
            }
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
    }

    private var productInfoBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(product.brand.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Color.secondary)

            Text(product.name)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {

            }) {
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= Int(product.rating.rounded()) ? "star.fill" : "star")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.black)
                    }
                    Text(String(format: "%.1f", product.rating))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }
            }
            .buttonStyle(.plain)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let salePrice = product.salePrice {
                    Text("$\(salePrice, specifier: "%.2f")")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.primary)
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.secondary)
                        .strikethrough(true, color: Color.secondary)
                } else {
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary)

            Text(product.description)
                .font(.system(size: 15))
                .foregroundStyle(Color.secondary)
                .lineSpacing(4)
                .lineLimit(isDescriptionExpanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isDescriptionExpanded.toggle() } }) {
                Text(isDescriptionExpanded ? "Show Less" : "Read More")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private var viewInARButton: some View {
        Button(action: { showARView = true }) {
            HStack(spacing: 10) {
                Image(systemName: "arkit")
                    .font(.system(size: 18, weight: .medium))
                Text("View in AR")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(0.5)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
            }
            .contentShape(Rectangle())
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 16)
            .frame(height: optionCardHeight)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(WSPressButtonStyle())
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    private var specsSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { isSpecsExpanded.toggle() }
            }) {
                HStack {
                    Text("Specifications")
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .rotationEffect(.degrees(isSpecsExpanded ? 90 : 0))
                        .foregroundStyle(Color.primary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16)
                .frame(height: optionCardHeight)
            }
            .buttonStyle(.plain)

            if isSpecsExpanded {
                VStack(spacing: 0) {
                    let specs = product.productSpecs.isEmpty ? exampleSpecs : product.productSpecs
                    ForEach(Array(specs.enumerated()), id: \.element.id) { index, spec in
                        HStack(alignment: .top, spacing: 12) {
                            Text(spec.label)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.secondary)
                                .frame(width: 120, alignment: .leading)
                            Text(spec.value)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(
                            Color(uiColor: index.isMultiple(of: 2) ? .clear : .secondarySystemBackground)
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
            }
        }
        .frame(minHeight: optionCardHeight, alignment: .top)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CUSTOMER REVIEWS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color.secondary)

            HStack {
                Text("\(product.reviewCount) Reviews")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.primary)
                    }
                    Spacer()
                    Text("2 days ago")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }

                Text("Excellent quality, totally worth the price! Williams Sonoma never disappoints with their collections.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.primary)
                    .lineLimit(3)

                Text("Sarah J.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondary)
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private var premiumPackagingCard: some View {
        Button(action: {
            withAnimation(.spring()) {
                giftPackaging.toggle()
            }
        }) {
            HStack(spacing: 14) {
                Image(systemName: "giftcard")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color.primary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Premium Packaging")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    Text("Luxury gift-ready packaging included")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Toggle("", isOn: $giftPackaging)
                    .tint(Color.black)
                    .labelsHidden()
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .frame(height: optionCardHeight)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(WSPressButtonStyle())
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private var relatedProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Similar Items")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 16)

            let relatedProducts = viewModel.products
                .filter { $0.category == product.category && $0.id != product.id }
                .prefix(6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(relatedProducts)) { relatedProduct in
                        NavigationLink(destination: ProductDetailView(product: relatedProduct)) {
                            WSProductCardHorizontal(product: relatedProduct)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 100)
    }

    private var stickyBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {

                Button(action: {
                    if isAddedToCart {
                        navManager.selectedTab = .cart
                        dismiss()
                    } else {
                        cartManager.add(product: product, quantity: 1, color: selectedVariant?.name, size: selectedSize, giftWrapped: giftPackaging, giftMessage: nil)
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                            isAddedToCart = true
                        }
                    }
                }) {
                    ZStack {
                        if isAddedToCart {
                            HStack(spacing: 8) {
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 14))
                                Text("GO TO CART")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(0.5)
                            }
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "cart.badge.plus")
                                    .font(.system(size: 14))
                                Text("ADD TO CART")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(0.5)
                            }
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        }
                    }
                    .clipped()
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.black, lineWidth: 1.5))
                }

                Button(action: {
                    showingRegistryPicker = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 14))
                        Text("ADD TO REGISTRY")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
            .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
        }
        .sheet(isPresented: $showingRegistryPicker) {
            RegistryPickerSheet(
                product: product,
                variant: selectedVariant,
                registryManager: registryManager,
                onAdded: { registryName in
                    addedRegistryName = registryName
                    showAddedToRegistryToast = true
                }
            )
            .presentationDetents([.medium, .large])
        }
        .alert(isPresented: $showAddedToRegistryToast) {
            Alert(
                title: Text("Added to Registry"),
                message: Text("\(product.name) has been added to \(addedRegistryName)."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var productShareItems: [Any] {
        let price = product.salePrice ?? product.price
        let description = product.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let shortDescription = description.count > 180
            ? "\(description.prefix(180))..."
            : description

        return [
            """
            \(product.name)
            Williams Sonoma
            $\(String(format: "%.2f", price))

            \(shortDescription)
            """
        ]
    }

    @ViewBuilder
    private func detailImage(for index: Int) -> some View {
        let imageValue = product.imageNames.indices.contains(index) ? product.imageNames[index] : nil

        if let imageValue, imageValue.hasPrefix("http"), let url = URL(string: imageValue) {
            CustomAsyncImage(url: url)
        } else if let imageValue, imageValue.hasPrefix("/") {
            CustomAsyncImage(url: APIConfig.baseURL.appendingPathComponent(String(imageValue.dropFirst())))
        } else if let imageValue {
            Image(imageValue)
                .resizable()
                .scaledToFit()
                .padding(24)
        } else {
            Image(systemName: "photo")
                .font(.system(size: 60, weight: .ultraLight))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
    }
}

private struct RegistryPickerSheet: View {
    let product: WSProduct
    let variant: WSProductColor?
    let registryManager: RegistryManager

    var onAdded: ((String) -> Void)?

    @State private var registries: [Registry] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var addingRegistryId: String?
    @State private var addedRegistryName: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading registries...")
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 30))
                            .foregroundStyle(.red)
                        Text("Failed to load registries")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if registries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "gift.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No registries found")
                            .font(.headline)
                        Text("Create a registry first to start adding products.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(registries) { registry in
                                Button {
                                    addProduct(to: registry)
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(registry.name)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(Color.primary)
                                            Text(registry.eventType.title)
                                                .font(.system(size: 14))
                                                .foregroundStyle(Color.secondary)
                                        }

                                        Spacer()

                                        if addedRegistryName == registry.name {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 17, weight: .bold))
                                                .foregroundStyle(Color.green)
                                        } else if addingRegistryId == registry.id {
                                            ProgressView()
                                            .controlSize(.small)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
                                }
                                .buttonStyle(.plain)
                                .disabled(addingRegistryId != nil || addedRegistryName != nil)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Select Registry")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if let addedRegistryName {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.green)
                        Text("Added to \(addedRegistryName)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .task {
                do {
                    registries = try await RegistryService.shared.loadRegistries()
                    isLoading = false
                } catch {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func addProduct(to registry: Registry) {
        guard addingRegistryId == nil, addedRegistryName == nil else { return }

        addingRegistryId = registry.id
        errorMessage = nil

        Task {
            do {
                let request = AddRegistryCartItemRequest(
                    productId: product.id.uuidString,
                    quantity: 1,
                    price: product.salePrice ?? product.price,
                    name: product.name,
                    imageUrl: product.primaryImageURL?.absoluteString ?? product.imageNames.first ?? "",
                    source: .manual,
                    status: .inCart
                )

                _ = try await RegistryService.shared.addCartItem(
                    registryId: registry.id,
                    requestBody: request
                )

                registryManager.addToRegistry(product, variant: variant)
                addedRegistryName = registry.name
                onAdded?(registry.name)

                try? await Task.sleep(for: .seconds(1.0))
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }

            addingRegistryId = nil
        }
    }
}

private struct ProductShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
