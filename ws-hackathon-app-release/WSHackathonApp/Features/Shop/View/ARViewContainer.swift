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
        context.coordinator.coachingOverlay = coachingOverlay

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

        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            DispatchQueue.main.async {
                self.viewModel.isCoachingActive = false
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView,
                  let entity = modelEntity else { return }

            let location = gesture.location(in: arView)

            var results = arView.raycast(
                from: location,
                allowing: .estimatedPlane,
                alignment: .horizontal
            )

            if results.isEmpty {
                results = arView.raycast(
                    from: location,
                    allowing: .existingPlaneGeometry,
                    alignment: .horizontal
                )
            }

            if results.isEmpty {
                results = arView.raycast(
                    from: location,
                    allowing: .existingPlaneInfinite,
                    alignment: .horizontal
                )
            }

            guard let firstResult = results.first else { return }

            if viewModel.placementState == .placed {
                currentAnchor?.removeFromParent()
            }

            let anchor = AnchorEntity(world: firstResult.worldTransform)

            let clonedEntity = entity.clone(recursive: true)
            clonedEntity.generateCollisionShapes(recursive: true)

            arView.installGestures(.all, for: clonedEntity)
            
            anchor.addChild(clonedEntity)
            arView.scene.addAnchor(anchor)

            currentAnchor = anchor
            placedEntity = clonedEntity

            DispatchQueue.main.async {
                self.viewModel.onModelPlaced()
            }
        }

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
