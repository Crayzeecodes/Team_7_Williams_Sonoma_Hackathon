//
//  WSHackathonAppApp.swift
//  WSHackathonApp
//
//  Williams Sonoma iOS App — Phase 1
//

import SwiftUI
import Supabase

@available(iOS 18.0, *)
@main
struct WSHackathonAppApp: App {
    @State private var navigationManager = NavigationManager()
    @State private var wishlistManager = WishlistManager()
    @State private var cartManager = WSCartManager()
    @State private var userManager = UserManager()

    @State private var isAuthenticated = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    WSTabView()
                } else {
                    AuthView()
                }
            }
            .task {
                // Initial check
                if let session = try? await supabase.auth.session {
                    self.isAuthenticated = true
                }

                for await state in supabase.auth.authStateChanges {
                    if [.initialSession, .signedIn, .passwordRecovery].contains(state.event) {
                        self.isAuthenticated = true
                    } else if [.signedOut, .userDeleted].contains(state.event) {
                        self.isAuthenticated = false
                        userManager.signOut() // Sync local manager
                    }
                }
            }
            .environment(navigationManager)
            .environment(wishlistManager)
            .environment(cartManager)
            .environment(userManager)
        }
    }
}
