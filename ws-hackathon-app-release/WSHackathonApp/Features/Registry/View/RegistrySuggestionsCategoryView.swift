//
//  RegistrySuggestionsCategoryView.swift
//  WSHackathonApp
//

import SwiftUI

struct RegistrySuggestionsCategoryView: View {
    let products: [RegistryProduct]
    let currencySymbol: String

    private let shopCategoryOrder = wsCategories.map(\.name)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(groupedSuggestions, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.primary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(section.products) { product in
                                    suggestionCard(product)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("All AI Suggestions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var groupedSuggestions: [(title: String, products: [RegistryProduct])] {
        var buckets: [String: [RegistryProduct]] = [:]

        for product in products {
            let title = mappedCategoryTitle(for: product.category)
            buckets[title, default: []].append(product)
        }

        let orderedTitles = shopCategoryOrder.filter { buckets[$0] != nil }
        let fallbackTitles = buckets.keys
            .filter { !orderedTitles.contains($0) }
            .sorted()

        return (orderedTitles + fallbackTitles).map { title in
            (title: title, products: buckets[title] ?? [])
        }
    }

    private func mappedCategoryTitle(for rawCategory: String) -> String {
        let normalizedRaw = normalize(rawCategory)

        if let match = shopCategoryOrder.first(where: { category in
            let normalizedCategory = normalize(category)
            return normalizedRaw == normalizedCategory
                || normalizedRaw.contains(normalizedCategory)
                || normalizedCategory.contains(normalizedRaw)
        }) {
            return match
        }

        return rawCategory
    }

    private func normalize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private func suggestionCard(_ product: RegistryProduct) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(width: 190, height: 150)
                .overlay(
                    AsyncImage(url: product.primaryImageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "photo")
                            .font(.system(size: 24, weight: .ultraLight))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                )
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(product.category.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.secondary)

                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                    .frame(minHeight: 40, alignment: .topLeading)

                Text("\(currencySymbol)\(product.price, specifier: "%.2f")")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.primary)
            }
            .padding(12)
        }
        .frame(width: 190)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}
