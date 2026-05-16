//
//  RegistrySuccessView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
import SwiftUI

struct RegistrySuccessView: View {
    
    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            
            Text("Registry Created 🎉")
                .font(.title)
                .fontWeight(.bold)
            
            Text(registryRepo.currentRegistry?.displayName ?? "")
                .font(.headline)
            
            Button("Start Browsing") {
                tabBarVM.resetRegistryFlow()
                tabBarVM.selectTab(.home)
            }
        }
        .padding()
    }
}
