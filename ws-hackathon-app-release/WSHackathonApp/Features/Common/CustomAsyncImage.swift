//
//  CustomAsyncImage.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import SwiftUI

struct CustomAsyncImage: View {    
    let url: URL?
    @StateObject private var loader = CustomImageLoader()
    
    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(.systemGray5)
                    ProgressView()
                }
            }
        }
        .onAppear {
            loader.load(url: url)
        }
    }
}
