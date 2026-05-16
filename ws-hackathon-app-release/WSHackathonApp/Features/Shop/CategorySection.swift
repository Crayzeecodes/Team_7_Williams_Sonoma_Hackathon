//
//  CategorySection.swift
//  WSHackathonApp
//
//  Category circles horizontal scroll layout.
//

import SwiftUI

struct CategorySection: View {
    let categories: [WSCategory]
    let allProducts: [WSProduct]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Shop by Category")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.primary)
                Spacer()
                NavigationLink(destination: AllCategoriesView(categories: categories, allProducts: allProducts)) {
                    HStack(spacing: 2) {
                        Text("See All")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(categories) { category in
                        WSCategoryCircleItem(category: category, allProducts: allProducts)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}

struct WSCategoryCircleItem: View {
    let category: WSCategory
    let allProducts: [WSProduct]

    var body: some View {
        NavigationLink(destination: ProductListView(
            title: category.name,
            products: allProducts.filter { $0.category == category.name || $0.occasions.contains(category.name) }
        )) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                        )

                    Image(systemName: category.icon)
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(Color.primary)
                }

                Text(category.name.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 72)
            }
        }
        .buttonStyle(.plain)
    }
}
