
import SwiftUI

@available(iOS 18.0, *)
struct WishlistView: View {
    @Environment(WishlistManager.self) private var wishlistManager

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if wishlistManager.items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(wishlistManager.items) { product in
                            NavigationLink(value: product) {
                                WSProductCardGrid(
                                    product: product,
                                    onWishlistToggle: { wishlistManager.toggle(product: product) },
                                    isWishlisted: true
                                )
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color(uiColor: .systemBackground))
            }
        }
        .navigationTitle("My Wishlist")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: WSProduct.self) { product in
            ProductDetailView(product: product)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
            Text("Your Wishlist is Empty")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary)
            Text("Save your favorite items to revisit later")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}
