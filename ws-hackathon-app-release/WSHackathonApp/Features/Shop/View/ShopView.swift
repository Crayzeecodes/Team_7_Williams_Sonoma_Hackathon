
import SwiftUI

private struct ShopSearchSuggestion: Identifiable, Hashable {
    let title: String
    let subtitle: String
    let iconName: String
    let priority: Int

    var id: String {
        "\(title)-\(subtitle)"
    }
}

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
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    searchExperience
                    BannerCarousel(allProducts: viewModel.products)
                    CategorySection(categories: viewModel.categories, allProducts: viewModel.products)
                    recommendationsSection
                    dealsSection
                }
                .padding(.top, 10)
                .padding(.bottom, 40)
            }
            .background(Color(uiColor: .systemBackground))
            .scrollDismissesKeyboard(.interactively)
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
                    products: searchResultProducts
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

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchResultProducts: [WSProduct] {
        guard !normalizedSearchText.isEmpty else { return [] }
        return viewModel.products.filter {
            $0.name.localizedCaseInsensitiveContains(normalizedSearchText) ||
            $0.brand.localizedCaseInsensitiveContains(normalizedSearchText) ||
            $0.category.localizedCaseInsensitiveContains(normalizedSearchText)
        }
    }

    private var searchSuggestions: [ShopSearchSuggestion] {
        guard !normalizedSearchText.isEmpty else { return [] }
        let query = normalizedSearchText.lowercased()

        let productSuggestions = viewModel.products
            .filter { product in
                product.name.lowercased().contains(query) ||
                product.brand.lowercased().contains(query) ||
                product.category.lowercased().contains(query)
            }
            .sorted { lhs, rhs in
                let lhsScore = suggestionScore(for: lhs.name, query: query)
                let rhsScore = suggestionScore(for: rhs.name, query: query)
                if lhsScore != rhsScore { return lhsScore < rhsScore }
                if lhs.rating != rhs.rating { return lhs.rating > rhs.rating }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            .prefix(4)
            .map {
                ShopSearchSuggestion(
                    title: $0.name,
                    subtitle: "\($0.brand) - \($0.category)",
                    iconName: "magnifyingglass",
                    priority: suggestionScore(for: $0.name, query: query)
                )
            }

        let categorySuggestions = uniqueValues(viewModel.products.map(\.category))
            .filter { $0.lowercased().contains(query) }
            .sorted { lhs, rhs in
                let lhsScore = suggestionScore(for: lhs, query: query)
                let rhsScore = suggestionScore(for: rhs, query: query)
                if lhsScore != rhsScore { return lhsScore < rhsScore }
                return lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
            .prefix(2)
            .map {
                ShopSearchSuggestion(
                    title: $0,
                    subtitle: "Category",
                    iconName: "square.grid.2x2",
                    priority: suggestionScore(for: $0, query: query)
                )
            }

        let brandSuggestions = uniqueValues(viewModel.products.map(\.brand))
            .filter { $0.lowercased().contains(query) }
            .sorted { lhs, rhs in
                let lhsScore = suggestionScore(for: lhs, query: query)
                let rhsScore = suggestionScore(for: rhs, query: query)
                if lhsScore != rhsScore { return lhsScore < rhsScore }
                return lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
            .prefix(2)
            .map {
                ShopSearchSuggestion(
                    title: $0,
                    subtitle: "Brand",
                    iconName: "tag",
                    priority: suggestionScore(for: $0, query: query)
                )
            }

        return Array(productSuggestions + categorySuggestions + brandSuggestions)
            .sorted {
                if $0.priority != $1.priority { return $0.priority < $1.priority }
                return $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
            .prefix(6)
            .map { $0 }
    }

    private var inlineCompletion: String? {
        guard
            isSearchFocused,
            !searchText.isEmpty,
            searchText == normalizedSearchText,
            let suggestion = searchSuggestions.first,
            suggestion.title.count > searchText.count,
            suggestion.title.lowercased().hasPrefix(searchText.lowercased())
        else {
            return nil
        }

        return suggestion.title
    }

    private var shouldShowSearchSuggestions: Bool {
        isSearchFocused && !normalizedSearchText.isEmpty
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

    private var searchExperience: some View {
        VStack(spacing: 8) {
            searchBar

            if shouldShowSearchSuggestions {
                searchSuggestionsPanel
            }
        }
        .padding(.horizontal, 16)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(Color.secondary)

            ZStack(alignment: .leading) {
                if let inlineCompletion {
                    HStack(spacing: 0) {
                        Text(searchText)
                            .foregroundStyle(.clear)
                        Text(String(inlineCompletion.dropFirst(searchText.count)))
                            .foregroundStyle(Color.secondary.opacity(0.55))
                    }
                    .font(.system(size: 16))
                    .lineLimit(1)
                    .allowsHitTesting(false)
                }

                TextField("Search kitchen, cookware, gifts...", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.primary)
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()
                    .onSubmit {
                        submitSearch()
                    }
            }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    private var searchSuggestionsPanel: some View {
        VStack(spacing: 0) {
            if searchSuggestions.isEmpty {
                Button {
                    submitSearch()
                } label: {
                    searchSuggestionRow(
                        title: "Search for \"\(normalizedSearchText)\"",
                        subtitle: "View matching products",
                        iconName: "arrow.up.left"
                    )
                }
                .buttonStyle(.plain)
            } else {
                ForEach(searchSuggestions) { suggestion in
                    Button {
                        applySearchSuggestion(suggestion.title)
                    } label: {
                        searchSuggestionRow(
                            title: suggestion.title,
                            subtitle: suggestion.subtitle,
                            iconName: suggestion.iconName
                        )
                    }
                    .buttonStyle(.plain)

                    if suggestion.id != searchSuggestions.last?.id {
                        Divider()
                            .padding(.leading, 46)
                    }
                }

                Divider()
                    .padding(.leading, 46)

                Button {
                    submitSearch()
                } label: {
                    searchSuggestionRow(
                        title: "View all results",
                        subtitle: "\(searchResultProducts.count) matching products",
                        iconName: "arrow.right.circle"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private func searchSuggestionRow(title: String, subtitle: String, iconName: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.secondary)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func applySearchSuggestion(_ suggestion: String) {
        searchText = suggestion
        submitSearch()
    }

    private func submitSearch() {
        guard !normalizedSearchText.isEmpty else { return }
        isSearchFocused = false
        showSearchResults = true
    }

    private func suggestionScore(for value: String, query: String) -> Int {
        let normalizedValue = value.lowercased()
        if normalizedValue.hasPrefix(query) { return 0 }
        if normalizedValue.split(separator: " ").contains(where: { $0.hasPrefix(query) }) { return 1 }
        if normalizedValue.contains(query) { return 2 }
        return 3
    }

    private func uniqueValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
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
