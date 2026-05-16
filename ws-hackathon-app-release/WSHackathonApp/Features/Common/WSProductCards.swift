//
//  WSProductCards.swift
//  WSHackathonApp
//
//  Product card components for grid and horizontal layouts.
//

import SwiftUI

// MARK: - Product Card Grid (2-column, equal height)
struct WSProductCardGrid: View {
    let product: WSProduct
    var onWishlistToggle: (() -> Void)? = nil
    var isWishlisted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Image area — 1:1 square
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        productImage(size: 28)
                    )
                    .clipped()

                // Wishlist heart
                if let onWishlistToggle {
                    Button(action: onWishlistToggle) {
                        Image(systemName: isWishlisted ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(isWishlisted ? Color.black : Color.primary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color(uiColor: .systemBackground).opacity(0.9))
                            )
                    }
                    .padding(8)
                    .accessibilityLabel(isWishlisted ? "Remove from wishlist" : "Add to wishlist")
                }
            }

            // Text area — fixed minimum height so all cards align
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
                    .frame(minHeight: 36, alignment: .topLeading)  // reserves 2-line space always

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
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.brand) \(product.name), \(product.price) dollars")
    }

    @ViewBuilder
    private func productImage(size: CGFloat) -> some View {
        if let imageURL = product.primaryImageURL {
            CustomAsyncImage(url: imageURL)
        } else if let assetName = product.imageNames.first, !assetName.hasPrefix("/") {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "photo")
                .font(.system(size: size, weight: .ultraLight))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
    }
}

// MARK: - Product Card Horizontal
struct WSProductCardHorizontal: View {
    let product: WSProduct
    var isWishlisted: Bool = false
    var onWishlistToggle: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Image — fixed size
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: 180, height: 160)
                    .overlay(
                        productImage(size: 26)
                    )
                    .clipped()

                Button(action: {
                    onWishlistToggle?()
                }) {
                    Image(systemName: isWishlisted ? "heart.fill" : "heart")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isWishlisted ? Color.black : Color.primary)
                        .padding(7)
                        .background(Circle().fill(Color(uiColor: .systemBackground).opacity(0.9)))
                }
                .padding(8)
            }

            // Text block
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
            }
            .padding(10)
            .frame(width: 180, alignment: .leading)
        }
        .frame(width: 180)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func productImage(size: CGFloat) -> some View {
        if let imageURL = product.primaryImageURL {
            CustomAsyncImage(url: imageURL)
        } else if let assetName = product.imageNames.first, !assetName.hasPrefix("/") {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "photo")
                .font(.system(size: size, weight: .ultraLight))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
    }
}
