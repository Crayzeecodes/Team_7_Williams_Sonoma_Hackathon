//
//  WSHackathonAppApp.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

@main
struct WSHackathonAppApp: App {
     @StateObject private var registryRepo = RegistryRepository()
     @StateObject private var cartRepo = CartRepository()
     @StateObject private var tabBarVM = WSTabBarViewModel()
    
    var body: some Scene {
        WindowGroup {
            WSTabView()
                .environmentObject(registryRepo)
                .environmentObject(cartRepo)
                .environmentObject(tabBarVM)
        }
    }
}
