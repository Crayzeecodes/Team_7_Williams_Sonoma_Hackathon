
import SwiftUI

#if !targetEnvironment(simulator)
import RealityKit
import ARKit
#endif

@available(iOS 18.0, *)
struct ARProductView: View {
    let product: WSProduct
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ARViewerViewModel

    #if !targetEnvironment(simulator)
    @State private var loadedModel: ModelEntity? = nil
    #endif

    init(product: WSProduct) {
        self.product = product
        self._viewModel = State(initialValue: ARViewerViewModel(product: product))
    }

    var body: some View {
        #if targetEnvironment(simulator)
        simulatorFallback
        #else
        arExperience
        #endif
    }

    private var simulatorFallback: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "arkit")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(.white)

                Text("AR View")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Point your camera at a flat surface\nto place \(product.name)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("AR requires a physical device.\nPlease run on iPhone or iPad.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            VStack {
                HStack {
                    Spacer()
                    dismissButton
                }
                Spacer()
            }
        }
    }

    #if !targetEnvironment(simulator)
    private var arExperience: some View {
        ZStack {

            ARViewContainer(viewModel: viewModel, modelEntity: loadedModel)
                .ignoresSafeArea()

            VStack {

                HStack {
                    dismissButton
                    Spacer()
                    if viewModel.placementState == .placed {
                        resetButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                if viewModel.placementState == .scanning && !viewModel.isCoachingActive {
                    coachingHint("Point at a flat surface")
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                if viewModel.placementState == .readyToPlace {
                    coachingHint("Tap to place product")
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                productInfoCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }

            if viewModel.modelLoadingState == .loading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                    Text("Loading 3D Model...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.placementState)
        .animation(.easeInOut(duration: 0.3), value: viewModel.modelLoadingState)
        .task {
            loadedModel = await viewModel.loadModel()
        }
        .onDisappear {

        }
    }
    #endif

    private var dismissButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .padding(20)
    }

    private var resetButton: some View {
        Button(action: {
            viewModel.resetPlacement()
            #if !targetEnvironment(simulator)
            loadedModel = nil
            Task {
                loadedModel = await viewModel.loadModel()
            }
            #endif
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .semibold))
                Text("Reset")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }

    private func coachingHint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }

    private var productInfoCard: some View {
        HStack(spacing: 12) {
            if let imgURL = product.primaryImageURL {
                CustomAsyncImage(url: imgURL)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            } else {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(product.brand.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                if let salePrice = product.salePrice {
                    Text("$\(salePrice, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .allowsHitTesting(false)
    }

    private var statusColor: Color {
        switch viewModel.placementState {
        case .scanning:     return .orange
        case .readyToPlace: return .yellow
        case .placed:       return .green
        }
    }

    private var statusText: String {
        switch viewModel.placementState {
        case .scanning:     return "Scanning..."
        case .readyToPlace: return "Ready"
        case .placed:       return "Placed"
        }
    }
}
