//
//  WSFilterSortSheets.swift
//  WSHackathonApp
//
//  Filter and Sort bottom sheet views + SeeAllProductsView.
//

import SwiftUI

// MARK: - Sort Sheet
struct WSSortSheet: View {
    @Binding var selectedSort: ShopViewModel.SortOption
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(ShopViewModel.SortOption.allCases, id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSort = option
                        }
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.rawValue)
                                .font(.system(size: 15))
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if selectedSort == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.black)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .listRowBackground(Color(uiColor: .systemBackground))
                }
            }
            .listStyle(.plain)
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Filter View
struct WSFilterView: View {
    @Binding var maxBudget: Double
    @Binding var selectedBrands: Set<String>
    let availableBrands: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Budget Slider
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BUDGET")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Color.secondary)

                        HStack {
                            Text("Up to")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                            Text("$\(Int(maxBudget))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.primary)
                        }

                        Slider(value: $maxBudget, in: 10...10000, step: 10)
                            .tint(Color.black)
                    }
                    .padding(.horizontal, 16)

                    Divider()

                    // Brands
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BRANDS")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal, 16)

                        ForEach(availableBrands, id: \.self) { brand in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    if selectedBrands.contains(brand) {
                                        selectedBrands.remove(brand)
                                    } else {
                                        selectedBrands.insert(brand)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: selectedBrands.contains(brand) ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 18))
                                        .foregroundStyle(selectedBrands.contains(brand) ? Color.black : Color(uiColor: .separator))

                                    Text(brand)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.primary)

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        maxBudget = 10000
                        selectedBrands.removeAll()
                    } label: {
                        Text("Reset")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.black)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Text("Apply")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.black)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - See All Products View (Sheet — kept for search results)
struct SeeAllProductsView: View {
    let title: String
    let products: [WSProduct]
    @Environment(\.dismiss) private var dismiss
    @Environment(WishlistManager.self) private var wishlistManager

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(products) { product in
                        NavigationLink(value: product) {
                            WSProductCardGrid(
                                product: product,
                                onWishlistToggle: { wishlistManager.toggle(product: product) },
                                isWishlisted: wishlistManager.isWishlisted(product)
                            )
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: WSProduct.self) { product in
                ProductDetailView(product: product)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
    }
}
