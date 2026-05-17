//
//  AppConstants.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
enum AppConstants {
    
    enum API {
        static var baseURL: String { APIConfig.baseURL.absoluteString }
        static var imageBasePath: String { APIConfig.baseURL.appendingPathComponent("images").absoluteString + "/" }
        static let timeout: TimeInterval = 30

        // FastAPI backend for AI features
        static let aiBaseURL = "http://192.168.1.9:8000"
        
        // Gemini Direct SDK Key (Read from .env file)
        static var geminiAPIKey: String {
            guard let path = Bundle.main.path(forResource: ".env", ofType: nil),
                  let content = try? String(contentsOfFile: path) else {
                print("⚠️ .env file not found or could not be read! Ensure it is added to Xcode's target.")
                return ""
            }
            
            for line in content.components(separatedBy: .newlines) {
                let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                if parts.count == 2, parts[0] == "GEMINI_API_KEY" {
                    return parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            return ""
        }
    }
}
