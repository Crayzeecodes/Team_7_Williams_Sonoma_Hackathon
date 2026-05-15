//
//  EmptyCartView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//
import SwiftUI
struct EmptyCartView: View {
    
    var onContinueShopping: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            VStack {
                HStack {
                    Text(AppStrings.Cart.emptyMessage)
                        .font(.headline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black)
                    Spacer()
                }.padding(16)
                 
                Button(action: {
                    onContinueShopping?()
                }) {
                    HStack {
                        Text(AppStrings.Cart.emptyButton)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .background(Color.white)
    }
}
