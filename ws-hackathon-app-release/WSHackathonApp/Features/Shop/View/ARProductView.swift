//
//  ARProductView.swift
//  WSHackathonApp
//
//  AR View stub — RealityKit integration is future scope.
//

import SwiftUI

struct ARProductView: View {
    let product: WSProduct
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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

                Text("AR integration coming soon")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 8)
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
        .accessibilityLabel("AR View for \(product.name). \(product.name) placed in augmented reality.")
    }
}
