//
//  RegistryItemRow.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//
import SwiftUI

struct RegistryItemRow: View {
    
    @StateObject private var viewModel: RegistryItemRowViewModel
    
    init(viewModel: RegistryItemRowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            
            CustomAsyncImage(url: viewModel.imageURL)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 6) {
                
                Text(viewModel.title)
                    .font(.subheadline)
                    .lineLimit(2)
                
                Text(viewModel.priceText)
                    .foregroundColor(.green)
                
                HStack {
                    Button(action: viewModel.decreaseQty) {
                        Image(systemName: "minus.circle.fill")
                    }
                    
                    Text(viewModel.quantityText)
                        .font(.caption)
                        .frame(minWidth: 20)
                    
                    Button(action: viewModel.increaseQty) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .foregroundColor(.black)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: viewModel.addToCart) {
                    Image(systemName: "cart.badge.plus")
                }
                .foregroundColor(.black)
                
                Button(action: viewModel.removeItem) {
                    Image(systemName: "trash")
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
