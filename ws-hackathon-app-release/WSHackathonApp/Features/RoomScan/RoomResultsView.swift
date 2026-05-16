//
//  RoomResultsView.swift
//  WSHackathonApp
//
//  Product results grid after room analysis, with Add to Cart / Registry actions.
//

import SwiftUI

@available(iOS 18.0, *)
struct RoomResultsView: View {
    @Bindable var viewModel: RoomScanViewModel
    @Environment(WSCartManager.self) private var cartManager
    @Environment(WishlistManager.self) private var wishlistManager

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // AI Insight Card
                if let result = viewModel.analysisResult {
                    insightCard(result)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                // Results Count
                Text("\(viewModel.recommendedProducts.count) curated picks for your room")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 16)

                if viewModel.recommendedProducts.isEmpty {
                    emptyState
                } else {
                    // Product Grid
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(viewModel.recommendedProducts) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                roomProductCard(product)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    // MARK: - AI Insight Card
    private func insightCard(_ result: RoomAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Text("AI Room Insight")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Color.primary)
            }

            Text(result.reasoning)
                .font(.system(size: 14))
                .foregroundStyle(Color.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            // Style Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    styleTag(result.detectedStyle, icon: "paintpalette")
                    ForEach(result.dominantColors.prefix(3), id: \.self) { color in
                        styleTag(color, icon: nil)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }

    private func styleTag(_ text: String, icon: String?) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
            }
            Text(text.capitalized)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(Capsule())
    }

    // MARK: - Product Card with Actions
    private func roomProductCard(_ product: WSProduct) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    )
                    .clipped()

                // Style Match Badge
                if let result = viewModel.analysisResult {
                    Text("Matches your \(result.detectedStyle) style")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.3)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(8)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.brand.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.8)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)

                Text(product.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                    .frame(minHeight: 36, alignment: .topLeading)

                if let salePrice = product.salePrice {
                    HStack(spacing: 6) {
                        Text("$\(salePrice, specifier: "%.2f")")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.primary)
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                            .strikethrough(color: Color.secondary)
                    }
                } else {
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }

                // Action Buttons
                HStack(spacing: 6) {
                    Button(action: {
                        cartManager.add(product: product)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 10))
                            Text("Cart")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Button(action: {
                        // Registry uses the RegistryManager pattern
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 10))
                            Text("Registry")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 6)
            }
            .padding(10)
        }
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))

            Text("No matching products found")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.primary)

            Text("Try adjusting your preferences\nor scanning a different room.")
                .font(.system(size: 14))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)

            Button(action: { viewModel.reset() }) {
                Text("TRY AGAIN")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(WSPressButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
