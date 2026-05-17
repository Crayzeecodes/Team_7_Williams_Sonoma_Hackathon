//
//  ShopViewModel.swift
//  WSHackathonApp
//
//  ViewModel for the Shop tab.
//

import Foundation

@Observable
class ShopViewModel {
    var searchText: String = ""
    var selectedCategory: String? = nil
    var sortOption: SortOption = .featured
    var maxBudget: Double = 10_000
    var selectedBrands: Set<String> = []
    var isLoading: Bool = false

    var products: [WSProduct] = []
    var categories: [WSCategory] = []
    var recommendations: [WSProduct] = []
    var deals: [WSDeal] = []
    var occasions: [WSOccasion] = []
    var collections: [WSCollection] = []

    // MARK: - Filtered Products
    var filteredProducts: [WSProduct] {
        var result = products

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.brand.lowercased().contains(query) ||
                $0.category.lowercased().contains(query)
            }
        }

        // Category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Budget filter
        if maxBudget < 10_000 {
            result = result.filter { ($0.salePrice ?? $0.price) <= maxBudget }
        }

        // Brand filter
        if !selectedBrands.isEmpty {
            result = result.filter { selectedBrands.contains($0.brand) }
        }

        // Sort
        switch sortOption {
        case .featured:
            result.sort { $0.isFeatured && !$1.isFeatured }
        case .priceHigh:
            result.sort { ($0.salePrice ?? $0.price) > ($1.salePrice ?? $1.price) }
        case .priceLow:
            result.sort { ($0.salePrice ?? $0.price) < ($1.salePrice ?? $1.price) }
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .topRated:
            result.sort { $0.rating > $1.rating }
        case .bestSelling:
            result.sort { $0.reviewCount > $1.reviewCount }
        }

        return result
    }

    var availableBrands: [String] {
        Array(Set(products.map(\.brand))).sorted()
    }

    var activeFilterCount: Int {
        var count = 0
        if selectedCategory != nil { count += 1 }
        if maxBudget < 10_000 { count += 1 }
        if !selectedBrands.isEmpty { count += selectedBrands.count }
        return count
    }

    var searchResults: [WSProduct] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return products.filter {
            $0.name.lowercased().contains(query) ||
            $0.brand.lowercased().contains(query) ||
            $0.category.lowercased().contains(query)
        }
    }

    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedProducts = try await WSService.shared.fetchProducts()
            products = loadedProducts

            let grouped = Dictionary(grouping: loadedProducts, by: \.category)
            categories = grouped.keys.sorted().enumerated().map { index, category in
                WSCategory(
                    id: index + 1,
                    name: category,
                    icon: Self.iconName(for: category),
                    productCount: grouped[category]?.count ?? 0,
                    imageAsset: nil
                )
            }

            recommendations = Array(
                loadedProducts.sorted { lhs, rhs in
                    if lhs.isFeatured != rhs.isFeatured {
                        return lhs.isFeatured && !rhs.isFeatured
                    }
                    return lhs.rating > rhs.rating
                }
                .prefix(8)
            )

            deals = loadedProducts
                .filter(\.isOnSale)
                .map { product in
                    WSDeal(
                        id: UUID(),
                        product: product,
                        discountType: "percentage",
                        discountValue: product.salePrice != nil
                            ? round((1 - product.salePrice! / product.price) * 100)
                            : 15,
                        validUntil: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                        couponCode: nil
                    )
                }

            occasions = try await WSService.shared.fetchOccasions()
            collections = try await WSService.shared.fetchCollections()
        } catch {
            print("Failed to load shop data: \(error)")
        }
    }

    func resetFilters() {
        selectedCategory = nil
        sortOption = .featured
        maxBudget = 10_000
        selectedBrands.removeAll()
    }

    // MARK: - Sort Options
    enum SortOption: String, CaseIterable {
        case featured    = "Featured"
        case priceHigh   = "Price: High to Low"
        case priceLow    = "Price: Low to High"
        case newest      = "Newest Arrivals"
        case topRated    = "Top Rated"
        case bestSelling = "Best Selling"
    }

    private static func iconName(for category: String) -> String {
        let normalized = category.lowercased()
        if normalized.contains("cookware") { return "flame" }
        if normalized.contains("knife") || normalized.contains("cutlery") { return "scissors" }
        if normalized.contains("bake") { return "birthday.cake" }
        if normalized.contains("electric") { return "bolt.circle" }
        if normalized.contains("coffee") || normalized.contains("tea") { return "cup.and.saucer" }
        if normalized.contains("food") { return "fork.knife" }
        if normalized.contains("outdoor") || normalized.contains("garden") { return "tree" }
        if normalized.contains("furniture") { return "sofa" }
        if normalized.contains("gift") { return "gift" }
        if normalized.contains("holiday") { return "snowflake" }
        if normalized.contains("home essential") || normalized.contains("home") { return "house" }
        if normalized.contains("new") { return "sparkles" }
        if normalized.contains("sale") { return "tag.fill" }
        if normalized.contains("tabletop") || normalized.contains("bar") { return "wineglass" }
        return "tag"
    }
}
