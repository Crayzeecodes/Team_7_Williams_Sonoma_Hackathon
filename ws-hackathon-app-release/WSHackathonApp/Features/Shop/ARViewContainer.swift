//
//  ARViewContainer.swift
//  WSHackathonApp
//
//  UIViewRepresentable wrapping RealityKit ARView with plane detection,
//  model placement, and gesture support.
//

import SwiftUI

#if !targetEnvironment(simulator)
import RealityKit
import ARKit

@available(iOS 18.0, *)
struct ARViewContainer: UIViewRepresentable {
    var viewModel: ARViewerViewModel
    var modelEntity: ModelEntity?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic

        // Enable people occlusion if supported
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        }

        arView.session.delegate = context.coordinator
        arView.session.run(config)

        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.delegate = context.coordinator
        arView.addSubview(coachingOverlay)
        context.coordinator.coachingOverlay = coachingOverlay

        // Add tap gesture for placement
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.modelEntity = modelEntity
        context.coordinator.viewModel = viewModel
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
        uiView.scene.anchors.removeAll()
        coordinator.currentAnchor = nil
        coordinator.placedEntity = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, modelEntity: modelEntity)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, ARSessionDelegate, ARCoachingOverlayViewDelegate {
        var viewModel: ARViewerViewModel
        var modelEntity: ModelEntity?
        var arView: ARView?
        var coachingOverlay: ARCoachingOverlayView?
        var currentAnchor: AnchorEntity?
        var placedEntity: ModelEntity?

        init(viewModel: ARViewerViewModel, modelEntity: ModelEntity?) {
            self.viewModel = viewModel
            self.modelEntity = modelEntity
        }

        // MARK: - ARSessionDelegate
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if anchor is ARPlaneAnchor {
                    DispatchQueue.main.async {
                        self.viewModel.onPlaneDetected()
                    }
                    break
                }
            }
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            print("AR Session failed: \(error.localizedDescription)")
        }

        func sessionWasInterrupted(_ session: ARSession) {
            print("AR Session interrupted")
        }

        func sessionInterruptionEnded(_ session: ARSession) {
            print("AR Session interruption ended")
        }

        // MARK: - ARCoachingOverlayViewDelegate
        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            DispatchQueue.main.async {
                self.viewModel.isCoachingActive = false
            }
        }

        // MARK: - Tap to Place
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView,
                  let entity = modelEntity else { return }

            let location = gesture.location(in: arView)

            // Raycast to find horizontal plane — try multiple strategies for reliability
            var results = arView.raycast(
                from: location,
                allowing: .estimatedPlane,
                alignment: .horizontal
            )
            
            // Fallback: existing plane geometry
            if results.isEmpty {
                results = arView.raycast(
                    from: location,
                    allowing: .existingPlaneGeometry,
                    alignment: .horizontal
                )
            }
            
            // Fallback: existing plane infinite
            if results.isEmpty {
                results = arView.raycast(
                    from: location,
                    allowing: .existingPlaneInfinite,
                    alignment: .horizontal
                )
            }

            guard let firstResult = results.first else { return }

            if viewModel.placementState == .placed {
                // Move existing model
                currentAnchor?.removeFromParent()
            }

            // Create anchor at hit position
            let anchor = AnchorEntity(world: firstResult.worldTransform)

            // Clone the entity for placement
            let clonedEntity = entity.clone(recursive: true)
            clonedEntity.generateCollisionShapes(recursive: true)

            // 1. Calculate the bounds of the raw model
            let bounds = clonedEntity.visualBounds(relativeTo: nil)
            
            // 2. Fix floating/off-center origins by moving the model so its bottom-center is at (0,0,0)
            clonedEntity.position = SIMD3<Float>(
                -bounds.center.x,
                -(bounds.center.y - (bounds.extents.y / 2.0)),
                -bounds.center.z
            )
            
            // 3. Create a wrapper entity to act as the new centered pivot
            let wrapper = ModelEntity()
            wrapper.addChild(clonedEntity)
            
            // 4. Scale the wrapper so the sofa is exactly 2 meters wide
            let maxDimension = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
            if maxDimension > 0 {
                wrapper.scale = SIMD3<Float>(repeating: 2.0 / maxDimension)
            } else {
                wrapper.scale = SIMD3<Float>(repeating: 0.002) // Fallback for mm scale
            }
            
            // 5. Install gestures and add to anchor
            wrapper.generateCollisionShapes(recursive: true)
            arView.installGestures(.all, for: wrapper)
            
            anchor.addChild(wrapper)
            arView.scene.addAnchor(anchor)

            currentAnchor = anchor
            placedEntity = wrapper

            DispatchQueue.main.async {
                self.viewModel.onModelPlaced()
            }
        }

        // MARK: - Reset
        func resetScene() {
            currentAnchor?.removeFromParent()
            currentAnchor = nil
            placedEntity = nil

            if let arView = arView {
                let config = ARWorldTrackingConfiguration()
                config.planeDetection = [.horizontal]
                config.environmentTexturing = .automatic

                if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
                    config.frameSemantics.insert(.personSegmentationWithDepth)
                }

                arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
            }
        }
    }
}
#endif
