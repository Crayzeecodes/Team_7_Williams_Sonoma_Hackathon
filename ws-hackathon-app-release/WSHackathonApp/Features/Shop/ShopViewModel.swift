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
        do {
            async let p = WSService.shared.fetchProducts()
            async let c = WSService.shared.fetchCategories()
            async let r = WSService.shared.fetchRecommendations()
            async let d = WSService.shared.fetchDeals()
            async let o = WSService.shared.fetchOccasions()
            async let col = WSService.shared.fetchCollections()

            products = try await p
            categories = try await c
            recommendations = try await r
            deals = try await d
            occasions = try await o
            collections = try await col
        } catch {
            print("Failed to load data: \(error)")
        }
        isLoading = false
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
}
