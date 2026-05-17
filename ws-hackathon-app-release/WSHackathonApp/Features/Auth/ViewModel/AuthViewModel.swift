
import Foundation
import Combine
import Supabase

class AuthViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false

    struct DBUser: Encodable {
        let id: UUID
        let email: String
        let name: String
        let password: String
    }

    @MainActor
    func login() async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await supabase.auth.signIn(email: email, password: password)

        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    func register() async {
        isLoading = true
        errorMessage = nil

        do {

            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )

            let user = response.user
            let dbUser = DBUser(
                id: user.id,
                email: email,
                name: name.isEmpty ? "New User" : name,
                password: password
            )

            try await supabase
                .from("users")
                .insert(dbUser)
                .execute()

            _ = try? await supabase.auth.signIn(email: email, password: password)

        } catch {
            errorMessage = "Signup failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    func resetPassword() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address to reset your password."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.resetPasswordForEmail(email)
            errorMessage = "Password reset email sent. Please check your inbox."
        } catch {
            errorMessage = "Failed to send reset email: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
