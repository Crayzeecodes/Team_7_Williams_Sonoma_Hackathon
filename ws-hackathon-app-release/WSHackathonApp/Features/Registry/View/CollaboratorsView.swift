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
            ScrollView {
                VStack(spacing: 12) {
                    Text("Join Code")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.secondaryText)
                    
                    Text(viewModel.registry?.joinCode ?? "------")
                        .font(.system(size: 48, weight: .bold))
                        .tracking(4)
                        .foregroundStyle(AppColors.accent)
                }
                .padding(40)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
                
                Button {
                    UIPasteboard.general.string = viewModel.registry?.joinCode
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy Code")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                    .background(AppColors.alwaysBlack)
                    .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("People Joined")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)

                    ForEach(peopleJoined) { person in
                        personRow(person)
                    }
                }
                .padding(.top, 20)
            }
            .padding(20)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Registry Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(AppColors.primaryText)
                    }
                }
            }
        }
    }

    private var peopleJoined: [JoinedPerson] {
        if !viewModel.members.isEmpty {
            return viewModel.members.map {
                JoinedPerson(
                    id: $0.id,
                    name: $0.displayName,
                    role: $0.role == .admin ? "Admin" : "Collaborator",
                    contributedBudget: $0.contributedBudget
                )
            }
        }

        guard let registry = viewModel.registry else { return [] }
        return [
            JoinedPerson(
                id: registry.adminId,
                name: registry.creatorName,
                role: "Admin",
                contributedBudget: registry.giftingDetails.creatorBudget
            )
        ]
    }

    private func personRow(_ person: JoinedPerson) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(initials(for: person.name))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                Text(person.role)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()

            if person.contributedBudget > 0 {
                Text("\(viewModel.currencySymbol)\(person.contributedBudget, specifier: "%.0f")")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
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

private struct JoinedPerson: Identifiable {
    let id: String
    let name: String
    let role: String
    let contributedBudget: Double
}
