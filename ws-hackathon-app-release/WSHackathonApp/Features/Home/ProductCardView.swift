//
//  ProductCardView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
import SwiftUI

struct ProductCardView: View {
    let product: ProductItem
    let quantity: Int
    let registryQuantity: Int
    let onAdd: () -> Void
    let onRemove: () -> Void
    let onAddToRegistry: () -> Void
    let onRemoveFromRegistry: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                
                AsyncImage(url: product.imageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: 150)
                            .clipped()
                            .cornerRadius(8)
                    } else if phase.error != nil {
                        ZStack {
                            Color(.systemGray5)
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.system(size: 30))
                        }
                        .frame(width: geo.size.width, height: 150)
                        .cornerRadius(8)
                    } else {
                        ZStack {
                            Color(.systemGray5)
                            ProgressView()
                        }
                        .frame(width: geo.size.width, height: 150)
                        .cornerRadius(8)
                    }
                }
            }
            .frame(height: 150) // fix GeometryReader height
            
            // Product Text
            Text(product.title)
                .font(.subheadline)
            
            Text(product.price?.formatted(.currency(code: "USD")) ?? "")
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            // Add To Cart
            if quantity == 0 {
                Button(action: onAdd) {
                    Text(AppStrings.Home.addToCartButton)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            } else {
                HStack {
                    Text(AppStrings.Cart.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 60, alignment: .leading)
                    
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill")
                    }
                    
                    Spacer()
                    
                    Text("\(quantity)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .font(.title3)
                .foregroundColor(.black)
            }
            // Add To Registry
            if registryQuantity == 0 {
                Button(AppStrings.Home.addToRegistry, action: onAddToRegistry)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            } else {
                HStack {
                    Text(AppStrings.Registry.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 60, alignment: .leading)
                    
                    Button(action: onRemoveFromRegistry) {
                        Image(systemName: "minus.circle.fill")
                    }
                    
                    Spacer()
                    
                    Text("\(registryQuantity)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button(action: onAddToRegistry) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .font(.title3)
                .foregroundColor(.black)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
        .frame(maxWidth: .infinity)
    }
}
