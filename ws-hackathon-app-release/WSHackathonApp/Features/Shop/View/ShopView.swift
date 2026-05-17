
import SwiftUI

@available(iOS 18.0, *)
struct ShopView: View {
    @State private var viewModel = ShopViewModel()
    @Environment(NavigationManager.self) private var navManager
    @Environment(WishlistManager.self) private var wishlistManager
    @Environment(WSCartManager.self) private var cartManager
    @Environment(UserManager.self) private var userManager

    @State private var searchText = ""
    @State private var showSearchResults = false
    @State private var showScanner = false
    @State private var showWishlist = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    searchBar
                    BannerCarousel(allProducts: viewModel.products)
                    CategorySection(categories: viewModel.categories, allProducts: viewModel.products)
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
            .sheet(isPresented: $showWishlist) {
                NavigationStack {
                    WishlistView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button {
                                    showWishlist = false
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.primary)
                                        .padding(8)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                        .clipShape(Circle())
                                }
                                .accessibilityLabel("Close wishlist")
                            }
                        }
                }
            }
            .sheet(isPresented: Bindable(navManager).showProfile) {
                ProfileModalView()
            }
        }
        .task { await viewModel.loadData() }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {

            Button(action: { showWishlist = true }) {
                Image(systemName: wishlistManager.items.isEmpty ? "heart" : "heart.fill")
                    .font(.system(size: 19))
                    .foregroundStyle(wishlistManager.items.isEmpty ? Color.primary : Color.red)
            }
            .accessibilityLabel("Wishlist")

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
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.horizontal, 16)
    }

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
