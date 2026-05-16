//
//  WSTabViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class WSTabBarViewModel: ObservableObject {
    
    @Published var selectedTab: TabItem = .shop
    @Published var cartItemCount: Int = 0

    
    var tabs: [TabItem] {
        TabItem.allCases
    }
    
    func selectTab(_ tab: TabItem) {
        selectedTab = tab
    }
    
}
