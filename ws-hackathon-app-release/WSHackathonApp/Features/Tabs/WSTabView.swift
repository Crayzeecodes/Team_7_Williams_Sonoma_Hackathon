//
//  WSTabView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

struct WSTabView: View {    
    @EnvironmentObject var viewModel: WSTabBarViewModel
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            ForEach(viewModel.tabs, id: \.rawValue) { tab in
                view(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
                    .badge(tab == .cart ? (viewModel.cartItemCount > 0 ? viewModel.cartItemCount : 0) : 0)
            }
        }
    }
    
    @ViewBuilder
    private func view(for tab: TabItem) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .registry:
            RegistryView()
        case .cart:
            CartView()
        }
    }
}

#Preview {
    WSTabView()
}
