//
//  ShopView.swift
//  WSHackathonApp
//
//  Main Shop tab matching the screenshot redesign.
//

import SwiftUI

struct ShopView: View {
    @State private var viewModel = ShopViewModel()
    @Environment(NavigationManager.self) private var navManager
    @Environment(WishlistManager.self) private var wishlistManager
    @Environment(WSCartManager.self) private var cartManager
    @Environment(UserManager.self) private var userManager

    @State private var searchText = ""
    @State private var showSearchResults = false
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    searchBar
                    BannerCarousel(allProducts: viewModel.products)
                    CategorySection(allProducts: viewModel.products)
                    recommendationsSection
                    dealsSection
                }
                .padding(.top, 10)
                .padding(.bottom, 40)
            }
            .background(Color(uiColor: .systemBackground))
            .refreshable { await viewModel.loadData() }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .navigationDestination(for: WSProduct.self) { product in
                ProductDetailView(product: product)
            }
            .sheet(isPresented: $showSearchResults) {
                SeeAllProductsView(
                    title: "Search Results",
                    products: viewModel.products.filter {
                        searchText.isEmpty ? false :
                        $0.name.localizedCaseInsensitiveContains(searchText) ||
                        $0.brand.localizedCaseInsensitiveContains(searchText) ||
                        $0.category.localizedCaseInsensitiveContains(searchText)
                    }
                )
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerView()
            }
            .sheet(isPresented: Bindable(navManager).showProfile) {
                ProfileModalView()
            }
        }
        .task { await viewModel.loadData() }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            // 1. Scan button
            Button(action: { showScanner = true }) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 19))
                    .foregroundStyle(Color.primary)
            }
            .accessibilityLabel("Scan product barcode")

            // 2. Wishlist button
            NavigationLink(destination: WishlistView()) {
                Image(systemName: "heart")
                    .font(.system(size: 19))
                    .foregroundStyle(Color.primary)
            }
            .accessibilityLabel("Wishlist")

            // 3. Profile avatar button
            Button(action: { navManager.showProfile = true }) {
                Circle()
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Text(userManager.currentUser?.initials ?? "WS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary)
                    )
                    .overlay(Circle().stroke(Color(uiColor: .separator), lineWidth: 0.5))
            }
            .accessibilityLabel("Profile")
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(Color.secondary)
            TextField("Search kitchen, cookware, gifts...", text: $searchText)
                .font(.system(size: 16))
                .foregroundStyle(Color.primary)
                .onSubmit {
                    if !searchText.isEmpty { showSearchResults = true }
                }
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    // MARK: - Recommended Section
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommended for You")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.primary)
                Spacer()
                NavigationLink(destination: ProductListView(title: "Recommended for You", products: viewModel.recommendations)) {
                    HStack(spacing: 2) {
                        Text("See All")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recommendations) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            WSProductCardHorizontal(
                                product: product,
                                isWishlisted: wishlistManager.isWishlisted(product),
                                onWishlistToggle: { wishlistManager.toggle(product: product) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Deals Section
    private var dealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Deals & Offers")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.primary)
                Spacer()
                NavigationLink(destination: ProductListView(title: "Deals & Offers", products: viewModel.deals.map(\.product))) {
                    HStack(spacing: 2) {
                        Text("See All")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.deals) { deal in
                        NavigationLink(destination: ProductDetailView(product: deal.product)) {
                            WSProductCardHorizontal(
                                product: deal.product,
                                isWishlisted: wishlistManager.isWishlisted(deal.product),
                                onWishlistToggle: { wishlistManager.toggle(product: deal.product) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }
}
