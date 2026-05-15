//
//  HomeView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    // MARK: - Search
                    TextField(AppStrings.Home.searchPlaceHolder, text: $viewModel.searchText)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding([.horizontal, .top], 16)
                    
                    // MARK: - Content
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        ScrollView {
                            let spacing: CGFloat = 16
                            let columns = [
                                GridItem(.flexible(), spacing: spacing),
                                GridItem(.flexible(), spacing: spacing)
                            ]
                            
                            LazyVGrid(columns: columns, spacing: spacing) {
                                ForEach(viewModel.filteredProducts) { product in
                                    ProductCardView(
                                        product: product,
                                        quantity: viewModel.quantity(for: product),
                                        registryQuantity: viewModel.registryQuantity(for: product),
                                        onAdd: { viewModel.addToCart(product) },
                                        onRemove: { viewModel.removeFromCart(product) },
                                        onAddToRegistry: {
                                            if viewModel.canAddToRegistry(product) {
                                                viewModel.addToRegistry(product)
                                            } else {
                                                tabBarVM.selectTab(.registry)
                                            }                                            
                                        },
                                        onRemoveFromRegistry: { viewModel.removeFromRegistry(product) }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .navigationTitle(AppStrings.Home.title)
            .onAppear {
                Task {
                    viewModel.bind(
                        cartRepository: cartRepository,
                        registryRepository: registryRepository
                    )
                    await viewModel.fetchProducts()
                }
            }
        }
    }
}
