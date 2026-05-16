//
//  SessionManager.swift
//  WSHackathonApp
//

import Foundation
import Combine

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var token: String? = nil
    @Published var currentUser: User? = nil
    
    struct User: Codable {
        let id: String
        let name: String
        let email: String
    }
    
    init() {
        // Load from UserDefaults later if needed
    }
    
    func login(token: String, user: User) {
        self.token = token
        self.currentUser = user
        self.isLoggedIn = true
    }
    
    func logout() {
        self.token = nil
        self.currentUser = nil
        self.isLoggedIn = false
    }
}
