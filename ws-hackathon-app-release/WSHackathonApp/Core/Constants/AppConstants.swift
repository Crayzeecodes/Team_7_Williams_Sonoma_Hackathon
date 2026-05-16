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

        // FastAPI backend for AI features (Room Scan, Claude analysis)
        static let aiBaseURL = "http://localhost:8000"
    }
}
