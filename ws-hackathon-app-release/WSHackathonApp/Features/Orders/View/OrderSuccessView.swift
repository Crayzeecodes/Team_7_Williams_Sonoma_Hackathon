//
//  OrderSuccessView.swift
//  WSHackathonApp
//

import SwiftUI

struct OrderSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    var onViewOrders: () -> Void
    
    @State private var circleScale: CGFloat = 0
    @State private var checkmarkScale: CGFloat = 0
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Animation group
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(circleScale)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 90, height: 90)
                        .scaleEffect(circleScale)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(checkmarkScale)
                }
                
                VStack(spacing: 12) {
                    Text("Order Placed Successfully")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.primary)
                    
                    Text("Thank you for shopping at Williams Sonoma. We've sent a confirmation email to your inbox.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(contentOpacity)
                
                Spacer()
                
                // Bottom Button
                VStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                        onViewOrders()
                    }) {
                        Text("View Order Details")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.black)
                            .clipShape(Capsule())
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Continue Shopping")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                circleScale = 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.3)) {
                checkmarkScale = 1
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.6)) {
                contentOpacity = 1
            }
        }
    }
}
