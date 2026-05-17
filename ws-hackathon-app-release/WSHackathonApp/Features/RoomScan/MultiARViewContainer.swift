//
//  MultiARViewContainer.swift
//  WSHackathonApp
//
//  AR container supporting multiple product placements via center-screen raycast.
//

import SwiftUI
import Combine
#if !targetEnvironment(simulator)
import RealityKit
import ARKit
#endif

@available(iOS 18.0, *)
class MultiARViewModel: ObservableObject {
    @Published var isCoachingActive = true
    @Published var selectedProduct: WSProduct?
    @Published var modelLoadingState: LoadingState = .idle
    @Published var planeDetected = false
    @Published var placedCount = 0
    @Published var lastSnapshot: UIImage?
    
    enum LoadingState { case idle, loading, success, failed }
}

#if !targetEnvironment(simulator)
@available(iOS 18.0, *)
struct MultiARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: MultiARViewModel
    @Binding var placeTrigger: Int  // Incremented each time user wants to place
    @Binding var snapshotTrigger: Int // Incremented to take a screenshot

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        arView.session.delegate = context.coordinator
        arView.session.run(config)
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.delegate = context.coordinator
        arView.addSubview(coachingOverlay)
        
        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Only place when trigger increments
        if placeTrigger > context.coordinator.lastPlaceTrigger {
            context.coordinator.lastPlaceTrigger = placeTrigger
            context.coordinator.placeSelectedModel()
        }
        // Take snapshot when trigger increments
        if snapshotTrigger > context.coordinator.lastSnapshotTrigger {
            context.coordinator.lastSnapshotTrigger = snapshotTrigger
            context.coordinator.takeSnapshot()
        }
    }
    
    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
        uiView.scene.anchors.removeAll()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, ARSessionDelegate, ARCoachingOverlayViewDelegate {
        var viewModel: MultiARViewModel
        var arView: ARView?
        var lastPlaceTrigger = 0
        var lastSnapshotTrigger = 0
        
        init(viewModel: MultiARViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - ARSessionDelegate
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if anchor is ARPlaneAnchor {
                    DispatchQueue.main.async { self.viewModel.planeDetected = true }
                    break
                }
            }
        }

        func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
            DispatchQueue.main.async { self.viewModel.isCoachingActive = true }
        }

        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            DispatchQueue.main.async { self.viewModel.isCoachingActive = false }
        }
        
        func takeSnapshot() {
            guard let arView = arView else { return }
            arView.snapshot(saveToHDR: false) { image in
                DispatchQueue.main.async {
                    self.viewModel.lastSnapshot = image
                }
            }
        }

        func placeSelectedModel() {
            guard let arView = arView, let _ = viewModel.selectedProduct else { return }
            
            // Try multiple raycast strategies for reliability
            let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            
            // Strategy 1: estimated plane
            var raycastResult = arView.raycast(from: screenCenter, allowing: .estimatedPlane, alignment: .horizontal).first
            
            // Strategy 2: existing plane geometry
            if raycastResult == nil {
                raycastResult = arView.raycast(from: screenCenter, allowing: .existingPlaneGeometry, alignment: .horizontal).first
            }
            
            // Strategy 3: existing plane (infinite)
            if raycastResult == nil {
                raycastResult = arView.raycast(from: screenCenter, allowing: .existingPlaneInfinite, alignment: .horizontal).first
            }
            
            guard let result = raycastResult else {
                DispatchQueue.main.async {
                    self.viewModel.modelLoadingState = .failed
                }
                return
            }
            
            DispatchQueue.main.async {
                self.viewModel.modelLoadingState = .loading
            }
            
            Task {
                let entity: ModelEntity
                
                // Try loading the bundled USDZ
                if let url = Bundle.main.url(forResource: "Sofa_Single", withExtension: "usdz"),
                   let loadedEntity = try? await ModelEntity(contentsOf: url) {
                    entity = loadedEntity
                } else {
                    // Procedural box fallback
                    let mesh = MeshResource.generateBox(width: 0.3, height: 0.3, depth: 0.3, cornerRadius: 0.02)
                    let material = SimpleMaterial(color: .systemBrown, isMetallic: false)
                    entity = ModelEntity(mesh: mesh, materials: [material])
                }
                
                entity.generateCollisionShapes(recursive: true)
                
                // Bounds-based scaling to realistic furniture size (~2m wide)
                let bounds = entity.visualBounds(relativeTo: nil)
                entity.position = SIMD3<Float>(
                    -bounds.center.x,
                    -(bounds.center.y - (bounds.extents.y / 2.0)),
                    -bounds.center.z
                )
                
                let wrapper = ModelEntity()
                wrapper.addChild(entity)
                
                let maxDimension = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
                if maxDimension > 0 {
                    wrapper.scale = SIMD3<Float>(repeating: 2.0 / maxDimension)
                } else {
                    wrapper.scale = SIMD3<Float>(repeating: 0.002)
                }
                
                wrapper.generateCollisionShapes(recursive: true)
                
                let anchor = AnchorEntity(world: result.worldTransform)
                anchor.addChild(wrapper)
                
                await MainActor.run {
                    arView.scene.addAnchor(anchor)
                    arView.installGestures(.all, for: wrapper)
                    self.viewModel.modelLoadingState = .success
                    self.viewModel.placedCount += 1
                }
            }
        }
    }
}
#endif
