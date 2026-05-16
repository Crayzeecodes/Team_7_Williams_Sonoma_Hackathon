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
            // Premium Dark Background
            LinearGradient(
                colors: [Color(hex: "#1A1A1A"), Color(hex: "#0A0A0A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
            // Decorative elements
            Circle()
                .fill(Color(hex: "#D4AF37").opacity(0.1))
                .frame(width: 400, height: 400)
                .offset(x: 200, y: -300)
                .blur(radius: 80)
            
            VStack(spacing: 32) {
                Spacer()
                
                // Header Section
                VStack(spacing: 12) {
                    Text("Williams Sonoma")
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .foregroundStyle(Color(hex: "#D4AF37"))
                        .tracking(4)
                        .padding(.bottom, 8)
                    
                    Text(isLoginMode ? "Welcome Back" : "Create Account")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text(isLoginMode ? "Sign in to continue your culinary journey" : "Join the world's finest home registry")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .multilineTextAlignment(.center)
                
                // Form Section
                VStack(spacing: 18) {
                    if !isLoginMode {
                        authField(title: "Full Name", text: $viewModel.name, icon: "person.fill")
                    }
                    
                    authField(title: "Email Address", text: $viewModel.email, icon: "envelope.fill", keyboardType: .emailAddress)
                    
                    authField(title: "Password", text: $viewModel.password, icon: "lock.fill", isSecure: true)
                    
                    if isLoginMode {
                        HStack {
                            Spacer()
                            Button("Forgot Password?") { }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "#D4AF37"))
                        }
                    }
                }
                .padding(.top, 20)
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Action Button
                VStack(spacing: 20) {
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
                                ProgressView().tint(.black)
                            } else {
                                Text(isLoginMode ? "Log In" : "Sign Up")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#D4AF37"), Color(hex: "#F9E29C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "#D4AF37").opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(viewModel.isLoading)
                    
                    // Social Logins
                    HStack(spacing: 40) {
                        socialButton(icon: "apple.logo")
                        socialButton(icon: "google.logo.custom")
                        socialButton(icon: "facebook.logo.custom")
                    }
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
                            .foregroundStyle(.white.opacity(0.6))
                        Text(isLoginMode ? "Sign Up" : "Log In")
                            .foregroundStyle(Color(hex: "#D4AF37"))
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 15))
                }
                .padding(.bottom, 20)
            }
            .padding(24)
        }
        .navigationBarHidden(true)
    }
    
    private func authField(title: String, text: Binding<String>, icon: String, isSecure: Bool = false, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.leading, 12)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(Color(hex: "#D4AF37"))
                    .frame(width: 24)
                
                if isSecure {
                    SecureField("", text: text)
                        .foregroundStyle(.white)
                } else {
                    TextField("", text: text)
                        .foregroundStyle(.white)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.none)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func socialButton(icon: String) -> some View {
        Button(action: { }) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 54, height: 54)
                
                if icon.contains("custom") {
                    // Placeholder for custom icons if needed
                    Circle().fill(.white.opacity(0.1)).frame(width: 24, height: 24)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview {
    AuthView()
}
