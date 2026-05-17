//
//  MultiARView.swift
//  WSHackathonApp
//
//  Full-screen AR experience: choose one product at a time,
//  place it in the scene, take snapshots, save to room.
//

import SwiftUI

@available(iOS 18.0, *)
struct MultiARView: View {
    let roomId: UUID
    
    @StateObject private var viewModel = MultiARViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var products: [WSProduct] = []
    @State private var placeTrigger = 0
    @State private var snapshotTrigger = 0
    @State private var showProductPicker = false
    @State private var placedProducts: [WSProduct] = []
    @State private var selectedCategory: String = "All"
    @State private var showSnapshotSaved = false
    
    init(roomId: UUID) {
        self.roomId = roomId
    }
    
    private var categories: [String] {
        var cats = Array(Set(products.map { $0.category })).sorted()
        cats.insert("All", at: 0)
        return cats
    }
    
    private var filteredProducts: [WSProduct] {
        if selectedCategory == "All" { return products }
        return products.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        ZStack {
            #if targetEnvironment(simulator)
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "arkit")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(.white)
                Text("AR requires a physical device.")
                    .foregroundStyle(.gray)
            }
            #else
            MultiARViewContainer(viewModel: viewModel, placeTrigger: $placeTrigger, snapshotTrigger: $snapshotTrigger)
                .ignoresSafeArea()
            
            // Center reticle
            if !viewModel.isCoachingActive && viewModel.modelLoadingState != .loading {
                VStack(spacing: 0) {
                    Circle()
                        .stroke(.white.opacity(0.8), lineWidth: 1.5)
                        .frame(width: 40, height: 40)
                    
                    Rectangle()
                        .fill(.white.opacity(0.5))
                        .frame(width: 1, height: 20)
                }
                .shadow(color: .black.opacity(0.4), radius: 3)
            }
            #endif
            
            // UI Overlay
            VStack(spacing: 0) {
                topBar
                Spacer()
                
                if !viewModel.isCoachingActive && !viewModel.planeDetected {
                    hintPill("Move your iPhone to scan the floor")
                }
                if viewModel.planeDetected && viewModel.selectedProduct == nil && !showProductPicker {
                    hintPill("Tap \"Choose Product\" below to get started")
                }
                
                Spacer()
                bottomPanel
            }
            
            // Loading overlay
            if viewModel.modelLoadingState == .loading {
                Color.black.opacity(0.4).ignoresSafeArea()
                    .allowsHitTesting(false)
                VStack(spacing: 12) {
                    ProgressView().tint(.white).scaleEffect(1.2)
                    Text("Placing product…")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            
            // Snapshot saved confirmation
            if showSnapshotSaved {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Snapshot saved!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 260)
                }
                .transition(.opacity)
                .allowsHitTesting(false)
            }
            
            // Product picker sheet
            if showProductPicker {
                productPickerOverlay
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
        .task {
            if let fetched = try? await WSService.shared.fetchProducts() {
                self.products = fetched
            }
        }
        .onChange(of: viewModel.lastSnapshot) { _, newSnapshot in
            guard let snapshot = newSnapshot else { return }
            saveSnapshotToRoom(snapshot)
        }
    }
    
    // MARK: - Save to Room
    private func saveSnapshotToRoom(_ image: UIImage) {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else { return }
        if var room = MyRoomStorage.shared.rooms.first(where: { $0.id == roomId }) {
            room.screenshotData.append(jpegData)
            MyRoomStorage.shared.updateRoom(room)
        }
        withAnimation { showSnapshotSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSnapshotSaved = false }
        }
    }
    
    private func saveProductsToRoom() {
        let ids = Array(Set(placedProducts.map { $0.id.uuidString }))
        if var room = MyRoomStorage.shared.rooms.first(where: { $0.id == roomId }) {
            let merged = Array(Set(room.productIds + ids))
            room.productIds = merged
            MyRoomStorage.shared.updateRoom(room)
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Snapshot button
            Button(action: { snapshotTrigger += 1 }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Button(action: { 
                saveProductsToRoom()
                dismiss() 
            }) {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(.white)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    // MARK: - Bottom Panel
    private var bottomPanel: some View {
        VStack(spacing: 12) {
            if viewModel.placedCount > 0 {
                Text("\(viewModel.placedCount) items placed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            
            if let selected = viewModel.selectedProduct {
                HStack(spacing: 12) {
                    if let imgURL = selected.primaryImageURL {
                        CustomAsyncImage(url: imgURL)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .id(selected.id)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selected.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(selected.brand)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showProductPicker = true }) {
                        Text("Add")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)
                
                Button(action: {
                    placeTrigger += 1
                    placedProducts.append(selected)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 14, weight: .bold))
                        Text("PLACE IN ROOM")
                            .font(.system(size: 15, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 16)
                
            } else {
                Button(action: { showProductPicker = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Choose Product")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: .systemBackground).opacity(0.95))
                .shadow(color: .black.opacity(0.15), radius: 20, y: -5)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Product Picker Overlay
    private var productPickerOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { showProductPicker = false }
            
            VStack(spacing: 0) {
                HStack {
                    Text("Select a Product")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    Button(action: { showProductPicker = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button(action: { selectedCategory = cat }) {
                                Text(cat)
                                    .font(.system(size: 13, weight: selectedCategory == cat ? .bold : .medium))
                                    .foregroundStyle(selectedCategory == cat ? .white : .primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == cat ? Color.black : Color(uiColor: .systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredProducts) { product in
                            Button(action: {
                                viewModel.selectedProduct = product
                                showProductPicker = false
                            }) {
                                HStack(spacing: 14) {
                                    if let imgURL = product.primaryImageURL {
                                        CustomAsyncImage(url: imgURL)
                                            .frame(width: 56, height: 56)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } else {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(uiColor: .tertiarySystemFill))
                                            .frame(width: 56, height: 56)
                                            .overlay(Image(systemName: "photo").foregroundStyle(.tertiary))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(product.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                        Text(product.brand)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                        Text("$\(product.price, specifier: "%.2f")")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    if viewModel.selectedProduct?.id == product.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.system(size: 20))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            Divider().padding(.leading, 90)
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(uiColor: .systemBackground))
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: showProductPicker)
    }
    
    private func hintPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .transition(.opacity)
    }
}
