//
//  WSHackathonAppApp.swift
//  WSHackathonApp
//
//  Williams Sonoma iOS App — Phase 1
//

import SwiftUI

@main
struct WSHackathonAppApp: App {
    @State private var navigationManager = NavigationManager()
    @State private var wishlistManager = WishlistManager()
    @State private var cartManager = WSCartManager()
    @State private var userManager = UserManager()

    var body: some Scene {
        WindowGroup {
            WSTabView()
                .environment(navigationManager)
                .environment(wishlistManager)
                .environment(cartManager)
                .environment(userManager)
        }
    }
}
