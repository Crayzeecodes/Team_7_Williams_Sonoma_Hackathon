//
//  APIConfig.swift
//  WSHackathonApp
//

import Foundation

enum APIConfig {
    static let baseURL = URL(string: "http://localhost:3001")!
    static let socketURL = URL(string: "http://localhost:3001")!
    static let registryBasePath = "/api/registry"
    static let requestTimeout: TimeInterval = 30

    static var authToken: String? {
        UserDefaults.standard.string(forKey: "ws_auth_token")
    }

    static var defaultHeaders: [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "x-user-email": "ios-demo@williams-sonoma.com",
            "x-user-name": "iOS Demo User"
        ]

        if let authToken, !authToken.isEmpty {
            headers["Authorization"] = "Bearer \(authToken)"
        }

        return headers
    }
}
