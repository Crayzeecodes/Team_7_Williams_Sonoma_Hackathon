
import SwiftUI

struct PiggyBankView: View {
    let budgetSnapshot: RegistryBudgetSnapshot
    let currencySymbol: String
    let trigger: Int

    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(currencySymbol)\(Int(budgetSnapshot.remainingAmount)) of \(currencySymbol)\(Int(budgetSnapshot.totalBudget)) remaining")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.primary)

                Text(progressLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(height: 16)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.black, AppColors.accent.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: animatedProgress == 0 ? 0 : max(16, proxy.size.width * animatedProgress),
                            height: 16
                        )
                }
            }
            .frame(height: 16)

            HStack {
                stat(title: "Spent", value: budgetSnapshot.spentAmount)
                Spacer()
                stat(title: "Budget", value: budgetSnapshot.totalBudget)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
        .onAppear {
            animateProgress()
        }
        .onChange(of: budgetSnapshot.remainingAmount) { _, _ in
            animateProgress()
        }
        .onChange(of: budgetSnapshot.totalBudget) { _, _ in
            animateProgress()
        }
        .onChange(of: trigger) { _, _ in
            animateProgress()
        }
    }

    private var progress: CGFloat {
        guard budgetSnapshot.totalBudget > 0 else { return 0 }
        let spentRatio = budgetSnapshot.spentAmount / budgetSnapshot.totalBudget
        return CGFloat(max(0.02, min(1, spentRatio)))
    }

    private var progressLabel: String {
        guard budgetSnapshot.totalBudget > 0 else { return "Set a budget to start tracking progress." }
        let percent = Int(round((budgetSnapshot.spentAmount / budgetSnapshot.totalBudget) * 100))
        if budgetSnapshot.remainingAmount == 0 {
            return "Budget reached"
        }
        return "\(percent)% of the budget has been allocated"
    }

    private func stat(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.secondary)
            Text("\(currencySymbol)\(Int(value))")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.primary)
        }
    }

    private func animateProgress() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            animatedProgress = progress
        }
    }
}
