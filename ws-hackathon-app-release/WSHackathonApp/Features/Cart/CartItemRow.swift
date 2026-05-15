//
//  CartItemRow.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import SwiftUI

struct CartItemRow: View {
    
    let item: CartItem
    let onAdd: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            let url = item.imageURL
            // MARK: - Image
            CustomAsyncImage(url: url)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .clipped()
            
            // MARK: - Info
            VStack(alignment: .leading, spacing: 6) {
                
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text("$\(item.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.black)
                
                Spacer()
                
                // MARK: - Quantity Controls
                HStack(spacing: 12) {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill")
                    }
                    
                    Text("\(item.quantity)")
                        .fontWeight(.medium)
                    
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .font(.title3)
                .foregroundColor(.black)
            }
            
            Spacer()
            
            // MARK: - Total Price per item
            Text("$\(item.price * Double(item.quantity), specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
    }
}
