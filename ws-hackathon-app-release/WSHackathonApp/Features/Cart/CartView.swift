//
//  CartView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

struct CartView: View {
    @StateObject private var viewModel = CartViewModel()
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                if viewModel.isEmptyCart {
                    VStack {
                        EmptyCartView {
                            tabBarVM.selectTab(.home)
                        }
                        Spacer()
                    }
                } else {
                    VStack(spacing: 0) {
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(viewModel.items) { item in
                                    CartItemRow(
                                        item: item,
                                        onAdd: { viewModel.add(item) },
                                        onRemove: { viewModel.removeItem(item) }
                                    )
                                }
                            }
                            .padding(16)
                        }
                        
                        // MARK: - Bottom Total View
                        VStack(spacing: 12) {
                            
                            HStack {
                                Text(AppStrings.Cart.total)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text(viewModel.totalPriceText)
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            
                            Button(action: {
                                // TODO: - Implement checkout flow
                            }) {
                                Text(AppStrings.Cart.checkoutButton)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16.0)
                        .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: -2)
                    }
                }
            }
            .navigationTitle(AppStrings.Cart.title)
        }
        .onAppear {
            Task {
                viewModel.bind(repository: cartRepository)
            }
        }
    }
}
