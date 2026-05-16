//
//  APIConfig.swift
//  WSHackathonApp
//

import Foundation

enum APIConfig {
    static let defaultBaseURLString: String = {
        // REPLACE with your Supabase Project URL (e.g. https://xyz.supabase.co)
        return "https://YOUR_SUPABASE_PROJECT_URL.supabase.co"
    }()

    static var baseURL: URL {
        if let override = UserDefaults.standard.string(forKey: "ws_api_base_url"),
           let url = URL(string: override),
           let scheme = url.scheme,
           !scheme.isEmpty {
            return url
        }

        return URL(string: defaultBaseURLString)!
    }

    static var authBaseURL: URL {
        baseURL.appendingPathComponent("auth/v1")
    }

    static var socketURL: URL {
        baseURL
    }

    static let registryBasePath = "/rest/v1/registries" // Standard Supabase REST path
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
