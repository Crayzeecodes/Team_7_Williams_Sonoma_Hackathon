//
//  AppConstants.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
enum AppConstants {
    
    enum API {
        static let baseURL = "http://localhost:3001"
        static let imageBasePath = baseURL + "/images/"
        static let timeout: TimeInterval = 30
    }
}
