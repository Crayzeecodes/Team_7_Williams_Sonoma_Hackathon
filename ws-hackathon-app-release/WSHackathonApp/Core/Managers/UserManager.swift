//
//  UserManager.swift
//  WSHackathonApp
//
//  Manages current user state.
//

import Foundation

@Observable
class UserManager {
    var currentUser: WSUser? = MockData.sampleUser

    var isLoggedIn: Bool { currentUser != nil }

    func signOut() {
        currentUser = nil
    }

    func signIn(user: WSUser) {
        currentUser = user
    }
}
