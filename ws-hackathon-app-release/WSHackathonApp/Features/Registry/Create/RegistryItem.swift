//
//  RegistryItem.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
struct RegistryItem: Identifiable {
    let id: String // productId
    let title: String
    let price: Double
    let imageUrl: String?
    var quantity: Int
}
