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
    var showOrders: Bool = false
    var activeOffers: [WSDeal] = []
    var pendingCategoryFilter: String? = nil
    var pendingSearchText: String? = nil

    var isAnyModalShowing: Bool {
        showProfile || showWishlist || showOffers || showScanner || showAllCategories || showOrders
    }

    enum AppTab: Int, CaseIterable, Identifiable {
        case shop = 0
        case cart
        case registry
        case scan

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .shop:     return "Shop"
            case .cart:     return "Cart"
            case .registry: return "Registry"
            case .scan:     return "Scan"
            }
        }

        var icon: String {
            switch self {
            case .shop:     return "storefront"
            case .cart:     return "cart"
            case .registry: return "gift"
            case .scan:     return "viewfinder"
            }
        }
    }
}
