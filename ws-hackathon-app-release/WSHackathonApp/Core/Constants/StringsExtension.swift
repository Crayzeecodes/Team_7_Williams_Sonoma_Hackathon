//
//  StringsExtension.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation

extension String {
    var htmlDecoded: String {
        var decoded = self
        
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'"
        ]
        
        entities.forEach { key, value in
            decoded = decoded.replacingOccurrences(of: key, with: value)
        }
        
        return decoded
    }
}
