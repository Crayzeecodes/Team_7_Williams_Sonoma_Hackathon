
import SwiftUI

enum RoomDetailFullScreen: Identifiable, Equatable {
    case arMode
    case gallery(index: Int)

    var id: String {
        switch self {
        case .arMode: return "arMode"
        case .gallery(let idx): return "gallery_\(idx)"
        }
    }
}

@available(iOS 18.0, *)
struct MyRoomDetailView: View {
    let roomId: UUID
    @State private var activeSheet: RoomDetailFullScreen?
    @State private var products: [WSProduct] = []
    @Environment(WSCartManager.self) private var cartManager

    init(roomId: UUID) {
        self.roomId = roomId
    }

    private var room: MyRoom? {
        MyRoomStorage.shared.rooms.first(where: { $0.id == roomId })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                Button(action: { activeSheet = .arMode }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arkit")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Enter AR Mode")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }

                if let room = room, !room.screenshotData.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Snapshots")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                            if room.screenshotData.count > 2 {
                                Button("View All") {
                                    activeSheet = .gallery(index: 0)
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.blue)
                            }
                        }

                        HStack(spacing: 12) {
                            ForEach(Array(room.screenshotData.prefix(2).enumerated()), id: \.offset) { offset, data in
                                if let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 25))
                                        .onTapGesture {
                                            activeSheet = .gallery(index: offset)
                                        }
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 50, weight: .ultraLight))
                            .foregroundStyle(Color.secondary)
                        Text("No Snapshots Yet")
                            .font(.headline)
                        Text("Enter AR Mode, place products, and take snapshots.")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }

                if !products.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Products Used")
                            .font(.system(size: 20, weight: .bold))

                        ForEach(products) { product in
                            VStack(spacing: 16) {
                                HStack(alignment: .top, spacing: 16) {
                                    if let imgURL = product.primaryImageURL {
                                        CustomAsyncImage(url: imgURL)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 25))
                                    } else {
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color(uiColor: .tertiarySystemFill))
                                            .frame(width: 80, height: 80)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.brand.uppercased())
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                        Text(product.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .lineLimit(2)
                                        Text("$\(product.price, specifier: "%.2f")")
                                            .font(.system(size: 16, weight: .bold))
                                            .padding(.top, 2)
                                    }
                                    Spacer()
                                }

                                HStack(spacing: 12) {
                                    Button(action: { cartManager.add(product: product) }) {
                                        Text("Add to Cart")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.black)
                                            .clipShape(RoundedRectangle(cornerRadius: 25))
                                    }

                                    Button(action: {  }) {
                                        Text("Add to Registry")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 25)
                                                    .stroke(Color.primary, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle(room?.name ?? "Room")
        .fullScreenCover(item: $activeSheet) { sheet in
            switch sheet {
            case .arMode:
                MultiARView(roomId: roomId)
            case .gallery(let index):
                if let room = room {
                    FullScreenGalleryView(imagesData: room.screenshotData, initialIndex: index)
                }
            }
        }
        .task {
            await loadProducts()
        }
        .onChange(of: activeSheet) { _, newSheet in
            if newSheet == nil {
                Task { await loadProducts() }
            }
        }
    }

    private func loadProducts() async {
        guard let room = room, !room.productIds.isEmpty else {
            products = []
            return
        }
        if let allProducts = try? await WSService.shared.fetchProducts() {
            products = allProducts.filter { room.productIds.contains($0.id.uuidString) }
        }
    }
}

struct FullScreenGalleryView: View {
    let imagesData: [Data]
    let initialIndex: Int
    @State private var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss

    init(imagesData: [Data], initialIndex: Int) {
        self.imagesData = imagesData
        self.initialIndex = initialIndex
        _selectedIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(imagesData.indices, id: \.self) { idx in
                    if let uiImage = UIImage(data: imagesData[idx]) {
                        Image(uiImage: uiImage)
                            .resizable()
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
