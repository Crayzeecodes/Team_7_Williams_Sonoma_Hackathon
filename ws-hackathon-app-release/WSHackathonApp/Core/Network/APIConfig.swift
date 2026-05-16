//
//  APIConfig.swift
//  WSHackathonApp
//

import Foundation

enum APIConfig {
    static let defaultBaseURLString: String = "https://ppgguekwthkygbzbjthl.supabase.co"
    static let supabaseAnonKey: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwZ2d1ZWt3dGhreWdiemJqdGhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NTExNTAsImV4cCI6MjA5NDUyNzE1MH0.3cdk-obcV-13QUJelVopY1GwBykbK7g3ZVPaXXEA0Dg"

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
            "apikey": supabaseAnonKey
        ]

        if let authToken, !authToken.isEmpty {
            headers["Authorization"] = "Bearer \(authToken)"
        } else {
            headers["Authorization"] = "Bearer \(supabaseAnonKey)"
        }

        return headers
    }
}
