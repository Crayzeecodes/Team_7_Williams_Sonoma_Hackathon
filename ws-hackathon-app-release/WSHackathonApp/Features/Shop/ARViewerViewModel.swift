//
//  ARViewerViewModel.swift
//  WSHackathonApp
//
//  ViewModel for the ARKit product viewer experience.
//

import Foundation
import SwiftUI

#if !targetEnvironment(simulator)
import RealityKit
import ARKit
#endif

@available(iOS 18.0, *)
@Observable
class ARViewerViewModel {

    // MARK: - State Enums
    enum ModelLoadingState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum PlacementState: Equatable {
        case scanning
        case readyToPlace
        case placed
    }

    // MARK: - Published State
    var modelLoadingState: ModelLoadingState = .idle
    var placementState: PlacementState = .scanning
    var isCoachingActive: Bool = true
    var product: WSProduct

    init(product: WSProduct) {
        self.product = product
    }

    // MARK: - USDZ Model Mapping
    /// Maps product names to their respective USDZ model files via keyword matching.
    /// Products without a specific match fall back to Sofa_Single.
    private static let defaultModelName = "Sofa_Single"

    /// Keyword-to-model mapping. Order matters — first match wins.
    private static let modelKeywords: [(keywords: [String], model: String)] = [
        (["victorian", "barrel", "leather sofa"],       "Sofa_Single"),
        (["harlow", "mid-century", "mid century"],      "Sofa_03"),
        (["armchair", "arm chair", "accent chair"],     "Arm_chair__Furniture"),
        (["espresso", "coffee maker", "barista"],       "Coffee_machine"),
        (["microwave"],                                 "l4d2_microwave"),
        (["fridge", "refrigerator"],                    "Not-too-modern_fridge"),
        (["sofa", "couch", "sectional", "loveseat"],    "Sofa_03"),
    ]

    /// Returns the bundle URL for the product's matching USDZ model.
    static func usdzURL(for product: WSProduct) -> URL? {
        let name = product.name.lowercased()
        for entry in modelKeywords {
            if entry.keywords.contains(where: { name.contains($0) }) {
                if let url = Bundle.main.url(forResource: entry.model, withExtension: "usdz") {
                    return url
                }
            }
        }
        // Default fallback
        return Bundle.main.url(forResource: defaultModelName, withExtension: "usdz")
    }

    /// Whether this product has an AR model available.
    /// Always true on device for the demo (Sofa_Single.usdz is bundled).
    static func hasARSupport(for product: WSProduct) -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    // MARK: - Model Loading
    #if !targetEnvironment(simulator)
    @MainActor
    func loadModel() async -> ModelEntity? {
        modelLoadingState = .loading

        // Load the bundled Sofa_Single.usdz for demo
        if let url = Self.usdzURL(for: product) {
            do {
                let entity = try await ModelEntity(contentsOf: url)
                entity.generateCollisionShapes(recursive: true)
                modelLoadingState = .loaded
                return entity
            } catch {
                print("USDZ load failed: \(error). Falling back to procedural model.")
            }
        }

        // Fallback: Create procedural box model if USDZ fails
        let entity = createProceduralModel()
        modelLoadingState = .loaded
        return entity
    }

    /// Creates a procedural 3D box model as a placeholder for demo.
    private func createProceduralModel() -> ModelEntity {
        let mesh = MeshResource.generateBox(
            width: 0.3,
            height: 0.3,
            depth: 0.3,
            cornerRadius: 0.02
        )

        // Use product category to pick a reasonable color
        let color: UIColor
        switch product.category {
        case "Cookware":
            color = UIColor(red: 0.7, green: 0.15, blue: 0.15, alpha: 1.0)
        case "Electrics":
            color = UIColor(red: 0.75, green: 0.75, blue: 0.78, alpha: 1.0)
        case "Tabletop & Bar":
            color = UIColor(red: 0.85, green: 0.82, blue: 0.76, alpha: 1.0)
        case "Bakeware":
            color = UIColor(red: 0.78, green: 0.68, blue: 0.45, alpha: 1.0)
        default:
            color = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1.0)
        }

        var material = SimpleMaterial()
        material.color = .init(tint: color)
        material.roughness = .float(0.3)
        material.metallic = .float(0.1)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.generateCollisionShapes(recursive: true)
        return entity
    }
    #endif

    // MARK: - Placement Control
    func onPlaneDetected() {
        if placementState == .scanning {
            placementState = .readyToPlace
            isCoachingActive = false
        }
    }

    func onModelPlaced() {
        placementState = .placed
    }

    func resetPlacement() {
        placementState = .scanning
        isCoachingActive = true
    }
}
