// PiggyBankView.swift
// WSHackathonApp — Custom SwiftUI Path-based animated piggy bank

import SwiftUI

struct PiggyBankView: View {

    /// 0.0 (empty) → 1.0 (full)
    let fillLevel: Double
    let totalBudget: Double
    let remainingAmount: Double
    let currencySymbol: String

    @State private var animatedFill: Double = 0
    @State private var isShaking: Bool = false
    @State private var coinParticles: [CoinParticle] = []

    private var fillColor: Color {
        if fillLevel > 0.5 {
            return Color(hex: "F2A623") // amber — healthy
        } else if fillLevel > 0.2 {
            return Color(hex: "E8893C") // orange — warning
        } else {
            return Color(hex: "E8593C") // red — critical
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Coin particles
                ForEach(coinParticles) { particle in
                    CoinParticleView(particle: particle)
                }

                // Piggy bank shape
                PiggyBankShape(fillLevel: animatedFill, fillColor: fillColor)
                    .frame(width: 140, height: 140)
                    .rotationEffect(isShaking ? .degrees(-6) : .degrees(0))
                    .animation(
                        isShaking ? .easeInOut(duration: 0.08).repeatCount(6, autoreverses: true) : .default,
                        value: isShaking
                    )
            }
            .frame(height: 160)

            // Budget text
            VStack(spacing: 4) {
                if remainingAmount == 0 && totalBudget > 0 {
                    Text("Budget Reached 🎉")
                        .font(.headline).fontWeight(.bold)
                        .foregroundStyle(Color(hex: "E8593C"))
                } else {
                    Text("\(currencySymbol)\(formatAmount(remainingAmount)) of \(currencySymbol)\(formatAmount(totalBudget)) remaining")
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.12))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(fillColor)
                            .frame(width: geo.size.width * animatedFill)
                    }
                }
                .frame(height: 6)
                .padding(.top, 4)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedFill = fillLevel
            }
        }
        .onChange(of: fillLevel) { oldVal, newVal in
            let dropped = newVal < oldVal
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                animatedFill = newVal
            }
            if dropped {
                triggerShake()
            } else {
                triggerCoinParticles()
            }
        }
    }

    // MARK: - Effects

    private func triggerShake() {
        isShaking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isShaking = false
        }
    }

    private func triggerCoinParticles() {
        let newParticles = (0..<5).map { i in
            CoinParticle(
                id: UUID(),
                offsetX: Double.random(in: -30...30),
                delay: Double(i) * 0.08
            )
        }
        coinParticles.append(contentsOf: newParticles)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            coinParticles.removeAll { p in newParticles.contains(where: { $0.id == p.id }) }
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "%.1fk", amount / 1000)
        }
        return String(format: "%.0f", amount)
    }
}

// MARK: - Piggy Bank Shape (SwiftUI Path)

private struct PiggyBankShape: View {
    let fillLevel: Double
    let fillColor: Color

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w * 0.5
            let cy = h * 0.52

            // Body (oval)
            let bodyRect = CGRect(x: cx - w * 0.38, y: cy - h * 0.3, width: w * 0.76, height: h * 0.6)
            let bodyPath = Path(ellipseIn: bodyRect)

            // Fill Height
            let fillHeight = h * 0.6 * fillLevel
            let fillY = bodyRect.maxY - fillHeight
            let fillRect = CGRect(x: bodyRect.minX, y: fillY, width: bodyRect.width, height: fillHeight)
            // Draw fill (approximated bottom fill without clip for compatibility)
            context.fill(bodyPath, with: GraphicsContext.Shading.color(fillColor.opacity(0.2)))
            
            // Draw body outline
            context.stroke(bodyPath, with: GraphicsContext.Shading.color(Color.white.opacity(0.15)), lineWidth: 2)

            // Snout (small circle right side)
            let snoutRect = CGRect(x: cx + w * 0.3, y: cy - h * 0.08, width: w * 0.2, height: h * 0.16)
            context.fill(Path(ellipseIn: snoutRect), with: GraphicsContext.Shading.color(Color.white.opacity(0.12)))
            context.stroke(Path(ellipseIn: snoutRect), with: GraphicsContext.Shading.color(Color.white.opacity(0.25)), lineWidth: 1.5)

            // Nostrils
            let n1 = CGRect(x: snoutRect.midX - 6, y: snoutRect.midY - 3, width: 5, height: 5)
            let n2 = CGRect(x: snoutRect.midX + 1, y: snoutRect.midY - 3, width: 5, height: 5)
            context.fill(Path(ellipseIn: n1), with: GraphicsContext.Shading.color(Color.white.opacity(0.3)))
            context.fill(Path(ellipseIn: n2), with: GraphicsContext.Shading.color(Color.white.opacity(0.3)))

            // Coin slot (top of body)
            let slotRect = CGRect(x: cx - 12, y: bodyRect.minY - 2, width: 24, height: 6)
            context.fill(Path(roundedRect: slotRect, cornerRadius: 3), with: GraphicsContext.Shading.color(Color.white.opacity(0.4)))

            // Eye
            let eyeRect = CGRect(x: cx + w * 0.1, y: cy - h * 0.18, width: 8, height: 8)
            context.fill(Path(ellipseIn: eyeRect), with: GraphicsContext.Shading.color(Color.white.opacity(0.8)))

            // Legs (4 small rounded rects)
            let legPositions: [CGFloat] = [cx - w*0.25, cx - w*0.1, cx + w*0.05, cx + w*0.2]
            for lx in legPositions {
                let legRect = CGRect(x: lx - 7, y: bodyRect.maxY - 5, width: 14, height: 18)
                context.fill(Path(roundedRect: legRect, cornerRadius: 6), with: GraphicsContext.Shading.color(Color.white.opacity(0.13)))
                context.stroke(Path(roundedRect: legRect, cornerRadius: 6), with: GraphicsContext.Shading.color(Color.white.opacity(0.2)), lineWidth: 1)
            }

            // Curly tail (left side)
            var tailPath = Path()
            let tailStart = CGPoint(x: cx - w*0.38, y: cy - h*0.05)
            tailPath.move(to: tailStart)
            tailPath.addCurve(
                to: CGPoint(x: tailStart.x - 18, y: tailStart.y - 10),
                control1: CGPoint(x: tailStart.x - 22, y: tailStart.y + 5),
                control2: CGPoint(x: tailStart.x - 25, y: tailStart.y - 5)
            )
            tailPath.addCurve(
                to: CGPoint(x: tailStart.x - 8, y: tailStart.y - 20),
                control1: CGPoint(x: tailStart.x - 12, y: tailStart.y - 15),
                control2: CGPoint(x: tailStart.x - 5, y: tailStart.y - 18)
            )
            context.stroke(tailPath, with: GraphicsContext.Shading.color(Color.white.opacity(0.4)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }
}

// MARK: - Coin Particle

struct CoinParticle: Identifiable {
    let id: UUID
    let offsetX: Double
    let delay: Double
}

private struct CoinParticleView: View {
    let particle: CoinParticle
    @State private var opacity: Double = 0
    @State private var offsetY: Double = 0

    var body: some View {
        Image(systemName: "dollarsign.circle.fill")
            .font(.system(size: 16))
            .foregroundStyle(Color(hex: "F2A623"))
            .offset(x: particle.offsetX, y: offsetY)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
                    withAnimation(.easeOut(duration: 0.9)) {
                        opacity = 1
                        offsetY = -60
                    }
                    withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
                        opacity = 0
                    }
                }
            }
    }
}
