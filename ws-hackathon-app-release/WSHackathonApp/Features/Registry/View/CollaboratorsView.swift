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
            VStack(spacing: 30) {
                Spacer()
                
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
                .background(AppColors.pureWhite)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                
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
                
                Spacer()
                Spacer()
            }
            .padding(20)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Share Registry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.primaryText)
                }
            }
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
