//
//  CategorySection.swift
//  WSHackathonApp
//
//  Category circles horizontal scroll layout.
//

import SwiftUI

let wsCategories: [WSCategory] = [
    WSCategory(id: 1, name: "Cookware", icon: "flame", productCount: 15, imageAsset: nil),
    WSCategory(id: 2, name: "Knives", icon: "scissors", productCount: 10, imageAsset: nil),
    WSCategory(id: 3, name: "Bakeware", icon: "birthday.cake", productCount: 8, imageAsset: nil),
    WSCategory(id: 4, name: "Electrics", icon: "bolt", productCount: 12, imageAsset: nil),
    WSCategory(id: 5, name: "Calphalon", icon: "frying.pan", productCount: 5, imageAsset: nil),
    WSCategory(id: 6, name: "Cutlery", icon: "fork.knife", productCount: 20, imageAsset: nil),
    WSCategory(id: 7, name: "Coffee & Tea", icon: "cup.and.saucer", productCount: 14, imageAsset: nil),
    WSCategory(id: 8, name: "Bartending", icon: "wineglass", productCount: 6, imageAsset: nil),
    WSCategory(id: 9, name: "Entertaining", icon: "sparkles", productCount: 18, imageAsset: nil),
    WSCategory(id: 10, name: "Outdoor", icon: "leaf", productCount: 22, imageAsset: nil),
    WSCategory(id: 11, name: "Food", icon: "bag", productCount: 30, imageAsset: nil),
    WSCategory(id: 12, name: "Gift Ideas", icon: "gift", productCount: 40, imageAsset: nil),
]

@available(iOS 18.0, *)
struct CategorySection: View {
    let allProducts: [WSProduct]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Shop by Category")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.primary)
                Spacer()
                NavigationLink(destination: AllCategoriesView(categories: wsCategories)) {
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
                    ForEach(wsCategories) { category in
                        WSCategoryCircleItem(category: category, allProducts: allProducts)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}

@available(iOS 18.0, *)
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
