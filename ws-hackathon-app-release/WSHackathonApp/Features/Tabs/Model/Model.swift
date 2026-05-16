//
//  Model.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation

enum TabItem: Int, CaseIterable, Identifiable {
    case shop = 0
    case cart
    case registry
    case orders
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .shop: return "Shop"
        case .cart: return "Cart"
        case .registry: return "Registry"
        case .orders: return "Orders"
        }
    }
    
    var icon: String {
        switch self {
        case .shop: return "bag"
        case .cart: return "cart"
        case .registry: return "list.clipboard"
        case .orders: return "shippingbox"
        }
    }
    
    static func from(rawValue: Int) -> TabItem? {
        return TabItem(rawValue: rawValue)
    }
}
