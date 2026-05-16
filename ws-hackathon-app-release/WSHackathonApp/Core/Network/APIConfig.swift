//
//  APIConfig.swift
//  WSHackathonApp
//

import Foundation

enum APIConfig {
    static let defaultBaseURLString: String = {
        return "http://Unnattis-MacBook-Air.local:3001"
    }()

    static var baseURL: URL {
        if let override = UserDefaults.standard.string(forKey: "ws_api_base_url"),
           let url = URL(string: override),
           let scheme = url.scheme,
           !scheme.isEmpty {
            return url
        }

        if let override = Bundle.main.object(forInfoDictionaryKey: "WSAPIBaseURL") as? String,
           let url = URL(string: override),
           let scheme = url.scheme,
           !scheme.isEmpty {
            return url
        }

        return URL(string: defaultBaseURLString)!
    }

    static var authBaseURL: URL {
        baseURL.appendingPathComponent("auth")
    }

    static var socketURL: URL {
        baseURL
    }

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
