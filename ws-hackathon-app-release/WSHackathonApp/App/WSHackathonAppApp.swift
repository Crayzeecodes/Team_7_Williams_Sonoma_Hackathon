//
//  WSHackathonAppApp.swift
//  WSHackathonApp
//
//  Williams Sonoma iOS App — Phase 1
//

import SwiftUI

@main
struct WSHackathonAppApp: App {
    // MARK: - Managers (iOS 17+ @Observable)
    @State private var navigationManager = NavigationManager()
    @State private var wishlistManager = WishlistManager()
    @State private var cartManager = WSCartManager()
    @State private var userManager = UserManager()

    // MARK: - Legacy Repositories (kept for existing Cart/Registry features)
    @StateObject private var registryRepo = RegistryRepository()
    @StateObject private var cartRepo = CartRepository()

    var body: some Scene {
        WindowGroup {
            WSTabView()
                .environment(navigationManager)
                .environment(wishlistManager)
                .environment(cartManager)
                .environment(userManager)
                .environmentObject(registryRepo)
                .environmentObject(cartRepo)
        }
    }
}
