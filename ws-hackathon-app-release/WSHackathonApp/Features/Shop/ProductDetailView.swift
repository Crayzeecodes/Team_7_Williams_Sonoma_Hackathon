//
//  ProductDetailView.swift
//  WSHackathonApp
//
//  Product detail matching v4 screenshot layout with full bleed image.
//

import SwiftUI

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

struct ProductDetailView: View {
    let product: WSProduct
    @Environment(WishlistManager.self) private var wishlistManager
    @Environment(WSCartManager.self) private var cartManager
    @Environment(\.dismiss) private var dismiss

    @State private var registryManager = RegistryManager()
    @State private var selectedVariant: WSProductColor? = nil
    @State private var selectedSize: String? = nil
    @State private var quantity: Int = 1
    @State private var giftPackaging: Bool = false
    @State private var isDescriptionExpanded: Bool = false
    @State private var isSpecsExpanded: Bool = false
    @State private var selectedImageIndex: Int = 0
    @State private var showARView = false
    @State private var showShareSheet = false
    @State private var isWishlisted = false
    @State private var reviews: [WSReview] = []
    
    // For related products
    @State private var viewModel = ShopViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    imageCarousel
                    pageDots
                    
                    productInfoBlock
                        .padding(.top, 32)

                    quantitySection
                    descriptionSection
                    specsSection
                    
                    if product.giftPackagingAvailable {
                        premiumPackagingCard
                    }
                    
                    WSProductReviewsView(productId: product.id, reviews: $reviews)
                    
                    relatedProductsSection
                }
            }
            .ignoresSafeArea(edges: .top) // Full bleed image
            .background(Color(uiColor: .systemBackground))
            
            stickyBottomBar
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: { isWishlisted.toggle() }) {
                    Image(systemName: isWishlisted ? "heart.fill" : "heart")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.primary)
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
            // ShareSheet(items: [product.name, product.id.uuidString])
            Text("Share Sheet coming soon") // Native Share sheet stub
        }
        .fullScreenCover(isPresented: $showARView) {
            ARProductView(product: product)
        }
        .onAppear {
            isWishlisted = wishlistManager.isWishlisted(product)
            selectedVariant = product.colors?.first
            selectedSize = product.sizes?.first
            reviews = MockData.reviews.filter { $0.productId == product.id }
            Task { await viewModel.loadData() }
        }
        .onChange(of: isWishlisted) { _, newValue in
            if newValue != wishlistManager.isWishlisted(product) {
                wishlistManager.toggle(product: product)
            }
        }
    }

    // MARK: - 6b. Image Carousel
    private var imageCarousel: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedImageIndex) {
                let count = max(1, product.imageNames.count)
                ForEach(0..<count, id: \.self) { index in
                    ZStack {
                        Color(uiColor: .secondarySystemBackground)
                        Image(systemName: "photo")
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: UIScreen.main.bounds.height * 0.52)
            
            // AR Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showARView = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arkit")
                                .font(.system(size: 12, weight: .semibold))
                            Text("View in AR")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                    }
                    .padding(.trailing, 14)
                    .padding(.bottom, 14)
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.52)
    }

    // MARK: - Page Dots
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

    // MARK: - 6c & 6d & 6e. Product Info
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
                // withAnimation { scrollToReviews = true }
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
                    Text("(\(product.reviewCount) reviews)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
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



    // MARK: - 6g. Quantity
    private var quantitySection: some View {
        HStack {
            Text("Quantity")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary)
            Spacer()
            HStack(spacing: 0) {
                Button(action: { if quantity > 1 { quantity -= 1 } }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(quantity > 1 ? Color.primary : Color.secondary)
                        .frame(width: 44, height: 44)
                }
                .disabled(quantity <= 1)

                Text("\(quantity)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 44, alignment: .center)

                Button(action: { quantity += 1 }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black)
                        .clipShape(Circle())
                }
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(uiColor: .separator), lineWidth: 0.5))
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    // MARK: - 6h. Description
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
    
    // MARK: - 6i. Specs
    private var specsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Specifications")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ForEach(Array(exampleSpecs.enumerated()), id: \.element.id) { index, spec in
                    HStack(alignment: .top, spacing: 12) {
                        Text(spec.label)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 130, alignment: .leading)
                        Text(spec.value)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Color(uiColor: index.isMultiple(of: 2)
                              ? .systemBackground
                              : .secondarySystemBackground)
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(uiColor: .separator), lineWidth: 0.5))
            .padding(.horizontal, 16)
        }
        .padding(.top, 32)
    }

    // MARK: - 6j. Premium Packaging
    private var premiumPackagingCard: some View {
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
            }

            Spacer()

            Toggle("", isOn: $giftPackaging)
                .tint(Color.black)
                .labelsHidden()
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }
    
    // MARK: - 6l. Related Products
    private var relatedProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You May Also Need")
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
        .padding(.bottom, 100)   // clearance above sticky bottom bar
    }

    // MARK: - 6n. Sticky Bottom Bar
    private var stickyBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                // Add to Cart — outline pill
                Button(action: {
                    cartManager.add(product: product, quantity: quantity, color: selectedVariant?.name, size: selectedSize, giftWrapped: giftPackaging, giftMessage: nil)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 14))
                        Text("ADD TO CART")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.black, lineWidth: 1.5))
                }

                // Add to Registry — filled pill
                Button(action: {
                    registryManager.addToRegistry(product, variant: selectedVariant)
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
    }
}
