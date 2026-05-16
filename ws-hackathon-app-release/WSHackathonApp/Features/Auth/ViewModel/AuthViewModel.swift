//
//  AuthViewModel.swift
//  WSHackathonApp
//

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
        let password: String // Required by the specific public.users schema provided
    }
    
    @MainActor
    func login() async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await supabase.auth.signIn(email: email, password: password)
            // Success! The session is handled automatically by the SDK.
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
            // 1. Sign up in Supabase Auth
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            
            // 2. Sync to public.users table (required for foreign keys)
            let user = response.user
            let dbUser = DBUser(
                id: user.id,
                email: email,
                name: name.isEmpty ? "New User" : name,
                password: password // Included to satisfy the schema's NOT NULL constraint
            )
            
            try await supabase
                .from("users")
                .insert(dbUser)
                .execute()
            
            // Success! Session is handled automatically.
            
        } catch {
            errorMessage = "Signup failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
