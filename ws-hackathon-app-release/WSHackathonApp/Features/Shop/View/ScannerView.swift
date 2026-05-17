//
//  ScannerView.swift
//  WSHackathonApp
//
//  Stub for product barcode scanner.
//

import SwiftUI

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                // Viewfinder graphic
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 260, height: 260)

                    // Corner accent lines
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 80, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.3))
                }

                Text("Scan a Product")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Point your camera at a product barcode\nor QR code to find it in the store")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("Camera integration coming soon")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)
            }

            // Close button top-right
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
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
        .accessibilityLabel("Product scanner. Camera integration coming soon.")
    }
}
