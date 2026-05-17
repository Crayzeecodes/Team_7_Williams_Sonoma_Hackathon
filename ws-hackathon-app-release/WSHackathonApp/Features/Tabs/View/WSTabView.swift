
import SwiftUI

@available(iOS 18.0, *)
struct WSTabView: View {
    @Environment(NavigationManager.self) private var navManager
    @Environment(WSCartManager.self) private var cartManager

    var body: some View {
        @Bindable var nav = navManager

        TabView(selection: $nav.selectedTab) {
            ShopView()
                .tabItem {
                    Label("Shop", systemImage: "bag.fill")
                }
                .tag(NavigationManager.AppTab.shop)

            CartView()
                .tabItem {
                    Label("Cart", systemImage: "cart.fill")
                }
                .tag(NavigationManager.AppTab.cart)
                .badge(cartManager.totalItems > 0 ? cartManager.totalItems : 0)

            RegistryListView()
                .tabItem {
                    Label("Registry", systemImage: "list.bullet")
                }
                .tag(NavigationManager.AppTab.registry)

            RoomScanRootView()
                .tabItem {
                    Label("Scan", systemImage: "viewfinder")
                }
                .tag(NavigationManager.AppTab.scan)
        }
        .tint(.black)
    }

    private func placeholderTab(icon: String, title: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
            Text("Coming Soon")
                .font(.headline)
                .foregroundStyle(Color.secondary)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        WSTabView()
            .environment(NavigationManager())
            .environment(WishlistManager())
            .environment(WSCartManager())
            .environment(UserManager())
    } else {

    }
}
