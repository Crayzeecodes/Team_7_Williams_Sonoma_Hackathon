//
//  SessionManager.swift
//  WSHackathonApp
//

import Foundation
import Combine

class SessionManager: ObservableObject {
    static let shared = SessionManager()

    private static let authTokenKey = "ws_auth_token"
    private static let currentUserKey = "ws_current_user"
    
    @Published var isLoggedIn: Bool = false
    @Published var token: String? = nil
    @Published var currentUser: User? = nil
    
    struct User: Codable {
        let id: String
        let name: String
        let email: String
    }
    
    init() {
        token = UserDefaults.standard.string(forKey: Self.authTokenKey)

        if let data = UserDefaults.standard.data(forKey: Self.currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
        }

        isLoggedIn = token?.isEmpty == false && currentUser != nil
    }
    
    func login(token: String, user: User) {
        self.token = token
        self.currentUser = user
        self.isLoggedIn = true
        UserDefaults.standard.set(token, forKey: Self.authTokenKey)
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Self.currentUserKey)
        }
    }
    
    func logout() {
        self.token = nil
        self.currentUser = nil
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: Self.authTokenKey)
        UserDefaults.standard.removeObject(forKey: Self.currentUserKey)
    }
}
