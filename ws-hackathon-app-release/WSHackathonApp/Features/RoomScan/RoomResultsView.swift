//
//  RoomResultsView.swift
//  WSHackathonApp
//
//  Product results grid after room analysis, with Add to Cart / Registry actions.
//

import SwiftUI

enum ResultGalleryState: Identifiable, Equatable {
    case remote(index: Int)
    case local(index: Int)
    
    var id: String {
        switch self {
        case .remote(let idx): return "remote_\(idx)"
        case .local(let idx): return "local_\(idx)"
        }
    }
}

@available(iOS 18.0, *)
struct RoomResultsView: View {
    @Bindable var viewModel: RoomScanViewModel
    @Environment(WSCartManager.self) private var cartManager
    @Environment(WishlistManager.self) private var wishlistManager
    @State private var activeGallery: ResultGalleryState?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Scanned Images
                if !viewModel.scannedImageUrls.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(viewModel.scannedImageUrls.enumerated()), id: \.offset) { index, urlStr in
                                if let url = URL(string: urlStr) {
                                    CustomAsyncImage(url: url)
                                        .frame(width: 140, height: 140)
                                        .clipShape(RoundedRectangle(cornerRadius: 25))
                                        .onTapGesture {
                                            activeGallery = .remote(index: index)
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                } else if !viewModel.capturedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(viewModel.capturedImages.enumerated()), id: \.offset) { idx, image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                    .onTapGesture {
                                        activeGallery = .local(index: idx)
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                }
                
                // AI Insight Card
                if let result = viewModel.analysisResult {
                    insightCard(result)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                // Results Count
                Text("\(viewModel.recommendedProducts.count) curated picks for your room")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 16)

                if viewModel.recommendedProducts.isEmpty {
                    emptyState
                } else {
                    // Product Grid
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(viewModel.recommendedProducts) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                roomProductCard(product)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .fullScreenCover(item: $activeGallery) { state in
            switch state {
            case .remote(let index):
                AsyncFullScreenGalleryView(urls: viewModel.scannedImageUrls, initialIndex: index)
            case .local(let index):
                UIImageFullScreenGalleryView(images: viewModel.capturedImages, initialIndex: index)
            }
        }
    }

    // MARK: - AI Insight Card
    private func insightCard(_ result: RoomAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Text("AI Room Insight")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Color.primary)
            }

            Text(result.reasoning)
                .font(.system(size: 14))
                .foregroundStyle(Color.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            // Style Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    styleTag(result.detectedStyle, icon: "paintpalette")
                    ForEach(result.dominantColors.prefix(3), id: \.self) { color in
                        styleTag(color, icon: nil)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }

    private func styleTag(_ text: String, icon: String?) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
            }
            Text(text.capitalized)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(Capsule())
    }

    // MARK: - Product Card with Actions
    private func roomProductCard(_ product: WSProduct) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        Group {
                            if let imageURL = product.primaryImageURL {
                                CustomAsyncImage(url: imageURL)
                            } else if let assetName = product.imageNames.first, !assetName.hasPrefix("/") {
                                Image(assetName)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 28, weight: .ultraLight))
                                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                            }
                        }
                    )
                    .clipped()

                // Style Match Badge
                if let result = viewModel.analysisResult {
                    Text("Matches your \(result.detectedStyle) style")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.3)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(8)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.brand.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.8)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)

                Text(product.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                    .frame(minHeight: 36, alignment: .topLeading)

                if let salePrice = product.salePrice {
                    HStack(spacing: 6) {
                        Text("$\(salePrice, specifier: "%.2f")")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.primary)
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                            .strikethrough(color: Color.secondary)
                    }
                } else {
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }

                // Action Buttons
                HStack(spacing: 6) {
                    Button(action: {
                        cartManager.add(product: product)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 10))
                            Text("Cart")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }

                    Button(action: {
                        // Registry uses the RegistryManager pattern
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 10))
                            Text("Registry")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 6)
                
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))

            Text("No matching products found")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.primary)

            Text("Try adjusting your preferences\nor scanning a different room.")
                .font(.system(size: 14))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)

            Button(action: { viewModel.reset() }) {
                Text("TRY AGAIN")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .buttonStyle(WSPressButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct AsyncFullScreenGalleryView: View {
    let urls: [String]
    let initialIndex: Int
    @State private var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    init(urls: [String], initialIndex: Int) {
        self.urls = urls
        self.initialIndex = initialIndex
        _selectedIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedIndex) {
                ForEach(urls.indices, id: \.self) { idx in
                    if let url = URL(string: urls[idx]) {
                        CustomAsyncImage(url: url)
                            .scaledToFit()
                            .tag(idx)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

struct UIImageFullScreenGalleryView: View {
    let images: [UIImage]
    let initialIndex: Int
    @State private var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    init(images: [UIImage], initialIndex: Int) {
        self.images = images
        self.initialIndex = initialIndex
        _selectedIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedIndex) {
                ForEach(images.indices, id: \.self) { idx in
                    Image(uiImage: images[idx])
                        .resizable()
                        .scaledToFit()
                        .tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
