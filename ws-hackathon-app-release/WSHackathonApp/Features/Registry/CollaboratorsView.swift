//
//  CollaboratorsView.swift
//  WSHackathonApp
//

import SwiftUI

struct CollaboratorsView: View {
    @ObservedObject var viewModel: RegistryDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.members) { member in
                    HStack(spacing: 14) {
                        Circle()
                            .fill(AppColors.surfaceMedium)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(initials(for: member.name))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(AppColors.primaryText)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.name)
                                .font(.system(size: 16, weight: .bold))
                            Text(member.joinedAt?.formatted(date: .abbreviated, time: .omitted) ?? "Joined recently")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppColors.secondaryText)
                        }

                        Spacer()

                        Text(member.role.rawValue.capitalized)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(member.role == .admin ? .white : AppColors.primaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(member.role == .admin ? AppColors.accent : AppColors.surfaceMedium)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 6)
                }

                if viewModel.members.contains(where: { $0.role != .admin }) {
                    Button(role: .destructive) {
                        Task {
                            if await viewModel.leaveRegistry() {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Leave")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.surfaceLight)
            .navigationTitle("Collaborators")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func initials(for name: String) -> String {
        name
            .split(separator: " ")
            .prefix(2)
            .map { String($0.prefix(1)) }
            .joined()
            .uppercased()
    }
}
