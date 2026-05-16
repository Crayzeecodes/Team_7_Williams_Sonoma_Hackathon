//
//  NavigationManager.swift
//  WSHackathonApp
//
//  Centralized navigation state for modals, sheets, and tab selection.
//

import SwiftUI

@Observable
class NavigationManager {
    var selectedTab: AppTab = .shop
    var showProfile: Bool = false
    var showWishlist: Bool = false
    var showOffers: Bool = false
    var showScanner: Bool = false
    var showAllCategories: Bool = false
    var activeOffers: [WSDeal] = []
    var pendingCategoryFilter: String? = nil
    var pendingSearchText: String? = nil

    var isAnyModalShowing: Bool {
        showProfile || showWishlist || showOffers || showScanner || showAllCategories
    }

    enum AppTab: Int, CaseIterable, Identifiable {
        case shop = 0
        case cart
        case registry
        case orders

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .shop:     return "Shop"
            case .cart:     return "Cart"
            case .registry: return "Registry"
            case .orders:   return "Orders"
            }
        }

        var icon: String {
            switch self {
            case .shop:     return "storefront"
            case .cart:     return "cart"
            case .registry: return "gift"
            case .orders:   return "shippingbox"
            }
        }
    }
}
