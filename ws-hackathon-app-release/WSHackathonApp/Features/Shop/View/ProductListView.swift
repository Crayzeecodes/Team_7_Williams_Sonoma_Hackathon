
import SwiftUI

@available(iOS 18.0, *)
struct ProductListView: View {
    let title: String
    let products: [WSProduct]
    @Environment(WishlistManager.self) private var wishlistManager

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(products.count) products")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 16)

                if products.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(products) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                WSProductCardGrid(
                                    product: product,
                                    onWishlistToggle: { wishlistManager.toggle(product: product) },
                                    isWishlisted: wishlistManager.isWishlisted(product)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
            Text("No products found")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
