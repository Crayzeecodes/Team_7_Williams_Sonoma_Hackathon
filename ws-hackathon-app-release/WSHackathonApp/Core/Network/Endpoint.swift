//
//  Endpoint.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
struct Endpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let queryParameters: [String: String]?

    var url: URL? {
        let fullString = AppConstants.API.baseURL + path
        guard let url = URL(string: fullString) else { return nil }
        
        if let queryParameters = queryParameters, !queryParameters.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            return components?.url
        }
        
        return url
    }

    init(path: String,
         method: HTTPMethod = .get,
         headers: [String: String]? = nil,
         queryParameters: [String: String]? = nil) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
    }
}
