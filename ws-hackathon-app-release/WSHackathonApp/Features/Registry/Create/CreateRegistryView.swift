//
//  CreateRegistryView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 04/04/26.
//

import SwiftUI

import SwiftUI

struct CreateRegistryView: View {
    
    @StateObject private var viewModel = CreateRegistryViewModel()
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    @EnvironmentObject var registryRepo: RegistryRepository
    
    @State private var navigateToSuccess = false
    
    private let spacing: CGFloat = 16
    
    var body: some View {
        ScrollView {
            VStack(spacing: spacing) {
                
                // MARK: - Header
                Text(AppStrings.Registry.createYourRegistry)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 32)
                
                // MARK: - Form fields
                VStack(spacing: spacing) {
                    
                    TextField(AppStrings.Registry.firstName, text: $viewModel.firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField(AppStrings.Registry.lastName, text: $viewModel.lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    VStack {
                        HStack {
                            Text(AppStrings.Registry.event)
                            Spacer()
                            // Event Picker
                            Picker(AppStrings.Registry.event, selection: $viewModel.selectedEvent) {
                                ForEach(RegistryEvent.allCases) { event in
                                    Text(event.title).tag(event)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        HStack {
                            Text(AppStrings.Registry.eventDate)
                            DatePicker(
                                "",
                                selection: $viewModel.date,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        // Date Picker
                    }.padding()
                    
                }
                
                // MARK: - Create Button
                Button(action: {
                    registryRepo.createRegistry(
                        firstName: viewModel.firstName,
                        lastName: viewModel.lastName,
                        event: viewModel.selectedEvent,
                        date: viewModel.date
                    )
                    navigateToSuccess = true
                }) {
                    Text(AppStrings.Registry.createButton)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isValid ? Color.black : Color.gray)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .disabled(!viewModel.isValid)
                .padding(.top, 16)
                Spacer()
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSuccess) {
            RegistrySuccessView()
        }
    }
}

#Preview {
    CreateRegistryView()
}
