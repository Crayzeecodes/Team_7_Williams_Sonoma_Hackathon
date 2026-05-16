// CollaboratorsView.swift
// WSHackathonApp

import SwiftUI

struct CollaboratorsView: View {
    let registryId: String
    let adminId: String
    let currentUserId: String
    @Binding var members: [RegistryMember]
    let onLeft: () -> Void

    @State private var isLeaving: Bool = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F1923").ignoresSafeArea()
                List {
                    ForEach(members) { member in
                        memberRow(member)
                            .listRowBackground(Color(hex: "1B2B4B").opacity(0.7))
                            .listRowSeparatorTint(.white.opacity(0.08))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Collaborators")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "F2A623"))
                }
            }
            .overlay(alignment: .bottom) {
                if let err = errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    @ViewBuilder
    private func memberRow(_ member: RegistryMember) -> some View {
        HStack(spacing: 14) {
            // Avatar initials circle
            ZStack {
                Circle()
                    .fill(member.role == .admin ? Color(hex: "F2A623") : Color(hex: "1B2B4B"))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(.white.opacity(0.15), lineWidth: 1))
                Text(initials(for: member.userId))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(member.role == .admin ? Color(hex: "0F1923") : .white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(member.userId == currentUserId ? "You" : member.userId)
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                        .lineLimit(1)
                    if member.role == .admin {
                        Text("ADMIN")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color(hex: "F2A623"))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color(hex: "F2A623").opacity(0.15), in: Capsule())
                    }
                }
                if let joined = member.joinedAt {
                    Text("Joined \(formatDate(joined))")
                        .font(.caption).foregroundStyle(.white.opacity(0.45))
                }
                if let budget = member.contributedBudget, budget > 0 {
                    Text("Budget: \(String(format: "%.0f", budget))")
                        .font(.caption2).foregroundStyle(Color(hex: "F2A623").opacity(0.8))
                }
            }

            Spacer()

            // Leave button (only show for current user, non-admin, or if admin is only member)
            if member.userId == currentUserId && member.role != .admin {
                Button {
                    Task { await leaveRegistry() }
                } label: {
                    if isLeaving {
                        ProgressView().tint(.red)
                    } else {
                        Text("Leave")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.red.opacity(0.75), in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func leaveRegistry() async {
        isLeaving = true
        do {
            try await RegistryService.shared.leave(id: registryId)
            members.removeAll { $0.userId == currentUserId }
            dismiss()
            onLeft()
        } catch {
            errorMessage = error.localizedDescription
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                errorMessage = nil
            }
        }
        isLeaving = false
    }

    private func initials(for userId: String) -> String {
        String(userId.prefix(2)).uppercased()
    }

    private func formatDate(_ dateStr: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: dateStr) {
            let f = DateFormatter()
            f.dateFormat = "dd MMM"
            return f.string(from: date)
        }
        return dateStr
    }
}
