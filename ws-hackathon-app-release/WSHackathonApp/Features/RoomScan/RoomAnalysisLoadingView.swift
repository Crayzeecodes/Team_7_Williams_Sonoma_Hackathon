//
//  RoomAnalysisLoadingView.swift
//  WSHackathonApp
//
//  Skeleton loading screen shown while Claude analyses room images.
//

import SwiftUI

struct RoomAnalysisLoadingView: View {
    @State private var animateGradient = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // AI Animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.05), Color.black.opacity(0.1)],
                            startPoint: animateGradient ? .topLeading : .bottomTrailing,
                            endPoint: animateGradient ? .bottomTrailing : .topLeading
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateGradient ? 1.1 : 0.95)

                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.primary)
                    .rotationEffect(.degrees(animateGradient ? 10 : -10))
            }
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: animateGradient)

            Spacer().frame(height: 32)

            Text("Analysing Your Room...")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.primary)

            Text("Our AI is identifying your room's style,\ncolors, and recommending products.")
                .font(.system(size: 15))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.top, 8)
                .padding(.horizontal, 32)

            Spacer().frame(height: 48)

            // Skeleton Cards
            skeletonGrid
                .padding(.horizontal, 16)

            Spacer()
        }
        .onAppear {
            animateGradient = true
        }
    }

    // MARK: - Skeleton Grid
    private var skeletonGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                skeletonCard
            }
        }
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color(uiColor: .secondarySystemBackground))
                .aspectRatio(1.0, contentMode: .fit)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(width: 60, height: 10)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(width: 80, height: 12)
            }
            .padding(10)
        }
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: -geo.size.width * 0.3 + geo.size.width * 1.6 * phase)
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .clipped()
            .onAppear { phase = 1 }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}
