
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
            .preferredColorScheme(.light)
            .task {

                if let session = try? await supabase.auth.session {
                    self.isAuthenticated = true
                    await loadUserProfile(userId: session.user.id)
                }

                for await state in supabase.auth.authStateChanges {
                    if [.initialSession, .signedIn, .passwordRecovery].contains(state.event) {
                        self.isAuthenticated = state.session != nil
                        if let userId = state.session?.user.id {
                            await loadUserProfile(userId: userId)
                        }
                    } else if [.signedOut, .userDeleted].contains(state.event) {
                        self.isAuthenticated = false
                        userManager.signOut()
                    }
                }
            }
            .environment(navigationManager)
            .environment(wishlistManager)
            .environment(cartManager)
            .environment(userManager)
        }
    }

    private func loadUserProfile(userId: UUID) async {

        if userManager.currentUser?.id == userId { return }

        do {
            struct UserRow: Decodable {
                let id: UUID
                let email: String
                let name: String
            }
            let rows: [UserRow] = try await supabase
                .from("users")
                .select("id, email, name")
                .eq("id", value: userId.uuidString)
                .execute()
                .value

            if let row = rows.first {

                let parts = row.name.split(separator: " ", maxSplits: 1).map(String.init)
                let firstName = parts.first ?? row.name
                let lastName = parts.count > 1 ? parts[1] : ""
                let wsUser = WSUser(
                    id: row.id,
                    firstName: firstName,
                    lastName: lastName,
                    email: row.email,
                    isKeyRewardsMember: false,
                    rewardPoints: 0
                )
                userManager.signIn(user: wsUser)
            }
        } catch {
            print("Failed to load user profile: \(error)")
        }
    }
}
