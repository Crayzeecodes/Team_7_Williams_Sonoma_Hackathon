//
//  PiggyBankView.swift
//  WSHackathonApp
//

import SwiftUI

struct PiggyBankView: View {
    let budgetSnapshot: RegistryBudgetSnapshot
    let currencySymbol: String
    let trigger: Int

    @State private var displayedFillLevel: CGFloat = 1
    @State private var tilt: Double = 0
    @State private var particles: [CoinParticle] = []

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                // Translucent Piggy Body
                PiggyBankShape()
                    .stroke(Color(hex: "#D4C9BB"), style: .init(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .background(
                        PiggyBankShape()
                            .fill(Color.white.opacity(0.3)) // More translucent
                    )
                    .frame(height: 220)
                
                // Static Coins inside
                let coinCount = Int(displayedFillLevel * 20)
                ForEach(0..<20, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: "#F2A623"))
                        .frame(width: 12, height: 12)
                        .offset(x: CGFloat.random(in: -40...40, seed: i), 
                                y: CGFloat.random(in: 0...60, seed: i))
                        .opacity(i < coinCount ? 0.9 : 0)
                        .animation(.easeInOut, value: displayedFillLevel)
                }
                .mask(PiggyBankShape().frame(height: 220))

                Rectangle()
                    .fill(Color(hex: "#C9BBA9"))
                    .frame(width: 54, height: 7)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .offset(y: -70)

                // Animation Particles (when triggered)
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color(hex: "#F2A623"))
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                }
            }
            .rotationEffect(.degrees(tilt))

            Text("\(currencySymbol)\(Int(budgetSnapshot.remainingAmount)) of \(currencySymbol)\(Int(budgetSnapshot.totalBudget)) remaining")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.primaryText)

            if budgetSnapshot.remainingAmount == 0 {
                Text("Budget reached")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.accent)
            }
        }
        .padding(20)
        .background(AppColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .onAppear {
            displayedFillLevel = fillLevel
        }
        .onChange(of: fillLevel) { oldValue, newValue in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
                displayedFillLevel = newValue
                tilt = newValue < oldValue ? -4 : 0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.12)) {
                tilt = 0
            }
        }
        .onChange(of: trigger) { _, _ in
            spawnCoins()
        }
    }

    private var fillLevel: CGFloat {
        guard budgetSnapshot.totalBudget > 0 else { return 0 }
        return max(0, min(1, budgetSnapshot.remainingAmount / budgetSnapshot.totalBudget))
    }

    private func spawnCoins() {
        particles = (0..<7).map { index in
            CoinParticle(
                id: UUID(),
                x: CGFloat(index * 8) - 24,
                y: 30,
                size: CGFloat(Int.random(in: 8...13)),
                opacity: 1
            )
        }

        withAnimation(.easeOut(duration: 1.0)) {
            particles = particles.map { particle in
                CoinParticle(
                    id: particle.id,
                    x: particle.x + CGFloat.random(in: -24...24),
                    y: particle.y - CGFloat.random(in: 70...120),
                    size: particle.size,
                    opacity: 0
                )
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            particles.removeAll()
        }
    }
}

// Helper for seeded random to keep coins static for a given index
extension CGFloat {
    static func random(in range: ClosedRange<CGFloat>, seed: Int) -> CGFloat {
        var generator = SeededRandomGenerator(seed: seed)
        return CGFloat.random(in: range, using: &generator)
    }
}

struct SeededRandomGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }
    func next() -> UInt64 {
        return UInt64(drand48() * Double(UInt64.max))
    }
}

private struct CoinParticle: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
}

private struct PiggyBankShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.addEllipse(in: CGRect(x: width * 0.12, y: height * 0.22, width: width * 0.58, height: height * 0.48))
        path.addEllipse(in: CGRect(x: width * 0.62, y: height * 0.34, width: width * 0.18, height: height * 0.18))
        path.addRect(CGRect(x: width * 0.22, y: height * 0.66, width: width * 0.06, height: height * 0.12))
        path.addRect(CGRect(x: width * 0.38, y: height * 0.66, width: width * 0.06, height: height * 0.12))
        path.addRect(CGRect(x: width * 0.56, y: height * 0.66, width: width * 0.06, height: height * 0.12))
        path.move(to: CGPoint(x: width * 0.12, y: height * 0.46))
        path.addQuadCurve(to: CGPoint(x: width * 0.06, y: height * 0.36), control: CGPoint(x: width * 0.04, y: height * 0.44))
        path.addQuadCurve(to: CGPoint(x: width * 0.12, y: height * 0.3), control: CGPoint(x: width * 0.07, y: height * 0.28))
        return path
    }
}
