//
//  AppConstants.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation

enum AppConstants {
    
    enum API {
        // Use 127.0.0.1 for better reliability in simulator than 'localhost'
        static let baseURL = "http://127.0.0.1:3001"
        static let imageBasePath = baseURL + "/images/"
        static let socketURL = baseURL
        static let timeout: TimeInterval = 30
    }
}
