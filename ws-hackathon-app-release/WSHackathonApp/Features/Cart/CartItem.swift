//
//  CartItem.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
struct CartItem: Identifiable {
    let id: String
    let title: String
    let price: Double
    let path: String?
    var quantity: Int
    
    var imageURL: URL? {
        guard let imageUrl = path else { return nil }
        if imageUrl.lowercased().hasPrefix("http") {
            return URL(string: imageUrl)
        }
        return URL(string: AppConstants.API.imageBasePath + imageUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
}
