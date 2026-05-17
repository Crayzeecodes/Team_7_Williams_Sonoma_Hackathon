//
//  AuthView.swift
//  WSHackathonApp
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isLoginMode = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Editorial Pure White Background
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 36) {
                Spacer()
                
                // Header Section
                VStack(spacing: 12) {
                    Text("WILLIAMS SONOMA")
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundStyle(AppColors.accent)
                        .tracking(3)
                        .padding(.bottom, 4)
                    
                    Text(isLoginMode ? "WELCOME" : "CREATE ACCOUNT")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(hex: "#7D9BB5")) // Pastel steel blue from the inspiration image
                        .tracking(2)
                    
                    Text(isLoginMode ? "Sign in to continue your culinary journey" : "Join the world's finest home registry")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                }
                .multilineTextAlignment(.center)
                
                // Form Section
                VStack(spacing: 20) {
                    if !isLoginMode {
                        authField(title: "FULL NAME", text: $viewModel.name, icon: "person")
                    }
                    
                    authField(title: "EMAIL ADDRESS", text: $viewModel.email, icon: "envelope", keyboardType: .emailAddress)
                    
                    authField(title: "PASSWORD", text: $viewModel.password, icon: "lock", isSecure: true)
                    
                    if isLoginMode {
                        HStack {
                            Spacer()
                            Button("Forgot Password?") { 
                                Task { await viewModel.resetPassword() }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "#7D9BB5"))
                        }
                    }
                }
                .padding(.top, 10)
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.red)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Action Button
                VStack(spacing: 24) {
                    Button(action: {
                        Task {
                            if isLoginMode {
                                await viewModel.login()
                            } else {
                                await viewModel.register()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView().tint(AppColors.pureWhite)
                            } else {
                                Text(isLoginMode ? "LOG IN" : "SIGN UP")
                                    .font(.system(size: 14, weight: .semibold))
                                    .tracking(2)
                            }
                        }
                        .foregroundStyle(AppColors.pureWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppColors.accent) // Sharp black rectangular button like "SHOP NOW"
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .disabled(viewModel.isLoading)
                }
                
                Spacer()
                
                // Footer
                Button(action: {
                    withAnimation(.spring()) {
                        isLoginMode.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                            .foregroundStyle(AppColors.secondaryText)
                        Text(isLoginMode ? "Sign Up" : "Log In")
                            .foregroundStyle(AppColors.accent)
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 15, weight: .medium))
                }
                .padding(.bottom, 20)
            }
            .padding(28)
        }
        .navigationBarHidden(true)
    }
    
    private func authField(title: String, text: Binding<String>, icon: String, isSecure: Bool = false, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .tracking(1)
            
            HStack(spacing: 12) {
                if isSecure {
                    SecureField("", text: text)
                        .foregroundStyle(AppColors.primaryText)
                } else {
                    TextField("", text: text)
                        .foregroundStyle(AppColors.primaryText)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.none)
                }
            }
            .font(.system(size: 15)) // Make text field content slightly larger
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(AppColors.background) // Pure white background
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(AppColors.border, lineWidth: 1) // Crisp, thin border
            )
        }
    }
    
    // Removed socialButton function since social buttons are no longer used
}

#Preview {
    AuthView()
}
