//
//  Helper.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
extension Endpoint {
    
    static func products() -> Endpoint {
        Endpoint(
            path: "/skus",
            method: .get
        )
    }
}
