// JoinRegistrySheet.swift
// WSHackathonApp

import SwiftUI

struct JoinRegistrySheet: View {
    @ObservedObject var viewModel: RegistryListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var joinCode: String = ""
    @State private var isChecking: Bool = false
    @State private var requiresBudget: Bool = false
    @State private var currency: CurrencyInfo = .usd
    @State private var budgetText: String = ""
    @State private var errorMessage: String?
    @State private var isJoining: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F1923").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 44))
                                .foregroundStyle(Color(hex: "F2A623"))
                            Text("Join a Registry")
                                .font(.title2).fontWeight(.bold).foregroundStyle(.white)
                            Text("Enter the 6-character code shared by the registry owner.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Code field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Join Code")
                                .font(.caption).fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.6))
                                .textCase(.uppercase)
                            TextField("e.g. AB12CD", text: $joinCode)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .onChange(of: joinCode) { _, new in
                                    joinCode = String(new.uppercased().prefix(6))
                                    requiresBudget = false
                                    errorMessage = nil
                                }
                                .font(.title3.monospaced())
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color(hex: "F2A623").opacity(joinCode.count == 6 ? 0.6 : 0.2))
                                )
                        }

                        // Dutch budget field (shown when required)
                        if requiresBudget {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Budget Contribution")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundStyle(.white.opacity(0.6)).textCase(.uppercase)
                                HStack {
                                    Text(currency.symbol)
                                        .font(.title3).foregroundStyle(Color(hex: "F2A623"))
                                    TextField("0.00", text: $budgetText)
                                        .keyboardType(.decimalPad)
                                        .foregroundStyle(.white)
                                        .font(.title3)
                                }
                                .padding(14)
                                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color(hex: "F2A623").opacity(0.4))
                                )
                                Text("This registry splits costs individually (Dutch).")
                                    .font(.caption).foregroundStyle(.white.opacity(0.45))
                            }
                            .transition(.asymmetric(
                                insertion: .push(from: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }

                        // Error
                        if let err = errorMessage {
                            Text(err)
                                .font(.subheadline).foregroundStyle(Color.red.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }

                        // Join Button
                        Button {
                            Task { await attemptJoin() }
                        } label: {
                            HStack {
                                if isJoining {
                                    ProgressView().tint(.black)
                                } else {
                                    Text(requiresBudget ? "Confirm & Join" : "Join Registry")
                                        .font(.headline).fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(joinCode.count == 6 ? Color(hex: "F2A623") : Color.gray.opacity(0.4))
                            .foregroundStyle(joinCode.count == 6 ? Color(hex: "0F1923") : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(joinCode.count != 6 || isJoining)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "F2A623"))
                }
            }
        }
    }

    private func attemptJoin() async {
        errorMessage = nil
        isJoining = true
        do {
            let budget = requiresBudget ? Double(budgetText) : nil
            _ = try await viewModel.joinRegistry(code: joinCode, budget: budget)
            dismiss()
        } catch {
            let msg = error.localizedDescription
            if msg.lowercased().contains("budget") || msg.lowercased().contains("dutch") {
                withAnimation { requiresBudget = true }
            } else {
                errorMessage = msg
            }
        }
        isJoining = false
    }
}
