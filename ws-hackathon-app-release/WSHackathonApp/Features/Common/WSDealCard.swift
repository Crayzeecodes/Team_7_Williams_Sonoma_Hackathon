//
//  WSDealCard.swift
//  WSHackathonApp
//
//  Deal card component for horizontal scroll.
//

import SwiftUI

// MARK: - Deal Card
struct WSDealCard: View {
    let deal: WSDeal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                ZStack {
                    Color(uiColor: .secondarySystemBackground)
                    Image(systemName: "tag.fill")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
                .frame(width: 180, height: 160)
                .clipped()

                // Discount badge
                Text(deal.discountLabel)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(deal.product.brand.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color.secondary)

                Text(deal.product.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text("$\(deal.salePrice, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    Text("$\(deal.product.price, specifier: "%.2f")")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                        .strikethrough()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(width: 180)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }
}
