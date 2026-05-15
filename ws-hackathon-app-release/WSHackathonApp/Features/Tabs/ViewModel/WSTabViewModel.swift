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
    
    @Published var selectedTab: TabItem = .home
    @Published var cartItemCount: Int = 0
    @Published var registryPath: [RegistryRoute] = []
    
    var tabs: [TabItem] {
        TabItem.allCases
    }
    
    func selectTab(_ tab: TabItem) {
        selectedTab = tab
    }
    
    func goToRegistrySuccess() {
        registryPath.append(.success)
    }
    
    func resetRegistryFlow() {
        registryPath.removeAll()
    }
}
