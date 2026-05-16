//
//  UserManager.swift
//  WSHackathonApp
//
//  Manages current user state.
//

import Foundation
import Supabase

@Observable
class UserManager {
    var currentUser: WSUser? = nil

    var isLoggedIn: Bool { currentUser != nil }

    func signOut() {
        Task {
            try? await supabase.auth.signOut()
            await MainActor.run {
                currentUser = nil
            }
        }
    }

    func signIn(user: WSUser) {
        currentUser = user
    }
}
