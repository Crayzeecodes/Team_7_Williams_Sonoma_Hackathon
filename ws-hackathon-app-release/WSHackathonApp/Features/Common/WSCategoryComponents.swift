//
//  WSCategoryComponents.swift
//  WSHackathonApp
//
//  Category chip and card components + AllCategoriesView (push nav).
//

import SwiftUI

// MARK: - Category Chip (Pill style for Shop tab)
struct WSCategoryChip: View {
    let category: WSCategory
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.system(size: 12))
            Text(category.name)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .background(isSelected ? Color.black : Color(uiColor: .secondarySystemBackground))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(isSelected ? Color.black : Color(uiColor: .separator), lineWidth: 0.5)
        )
        .accessibilityLabel("\(category.name), \(category.productCount) products")
    }
}

// MARK: - Category Card (uniform size for AllCategoriesView)
struct WSCategoryCard: View {
    let category: WSCategory

    var body: some View {
        VStack(spacing: 10) {
            Spacer()

            Image(systemName: category.icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.primary)

            Text(category.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("\(category.productCount) items")
                .font(.caption2)
                .foregroundStyle(Color.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }
}

// MARK: - All Categories View (Push navigation, not sheet)
@available(iOS 18.0, *)
struct AllCategoriesView: View {
    let categories: [WSCategory]
    let allProducts: [WSProduct]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(categories) { category in
                    NavigationLink(destination: ProductListView(
                        title: category.name,
                        products: allProducts.filter { $0.category == category.name }
                    )) {
                        WSCategoryCard(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("All Categories")
        .navigationBarTitleDisplayMode(.large)
    }
}
