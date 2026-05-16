//
//  RegistryDetailView.swift
//  WSHackathonApp
//

import SwiftUI

struct RegistryDetailView: View {
    @StateObject private var viewModel: RegistryDetailViewModel

    init(registryID: String) {
        _viewModel = StateObject(wrappedValue: RegistryDetailViewModel(registryID: registryID))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let registry = viewModel.registry {
                    header(registry)
                    PiggyBankView(
                        budgetSnapshot: viewModel.budgetSnapshot,
                        currencySymbol: viewModel.currencySymbol,
                        trigger: viewModel.coinAnimationTrigger
                    )
                    aiSuggestionsSection
                    sharedCartSection
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .padding(16)
        }
        .background(AppColors.surfaceLight.ignoresSafeArea())
        .navigationTitle(viewModel.registry?.name ?? "Registry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.isPresentingCollaborators = true
                } label: {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(AppColors.primaryText)
                }
            }
        }
        .sheet(isPresented: $viewModel.isPresentingCollaborators) {
            CollaboratorsView(viewModel: viewModel)
        }
        .task {
            await viewModel.load()
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }

    private func header(_ registry: Registry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(registry.creatorName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.secondaryText)
            Text(registry.eventType.title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
            Text("Join code: \(registry.joinCode)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.accent)
            Text(registry.eventDate.formatted(date: .complete, time: .omitted))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    private var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("AI Suggestions")
                    .font(.system(size: 22, weight: .bold))
                Spacer()
                Button("Refresh suggestions") {
                    Task { await viewModel.refreshSuggestions() }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.accent)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.suggestions) { suggestion in
                        suggestionCard(suggestion)
                    }
                }
            }
        }
    }

    private func suggestionCard(_ suggestion: RegistryAISuggestion) -> some View {
        let product = suggestion.productId.product
        return VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: product?.primaryImageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(AppColors.surfaceMedium)
                    .overlay(ProgressView())
            }
            .frame(width: 210, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Text(product?.name ?? "Recommended product")
                .font(.system(size: 16, weight: .bold))
                .lineLimit(2)

            Text("\(viewModel.currencySymbol)\(product?.price ?? 0, specifier: "%.0f")")
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.surfaceMedium)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppColors.accent)
                                .frame(width: proxy.size.width * suggestion.score)
                        }
                }
                .frame(height: 8)

                Text(suggestion.reasoning)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }

            Button {
                Task { await viewModel.addSuggestionToCart(suggestion) }
            } label: {
                Text("Add to Cart")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.alwaysBlack)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 240, alignment: .leading)
        .background(AppColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    private var sharedCartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Shared Cart")
                .font(.system(size: 22, weight: .bold))

            ForEach(viewModel.cartItems) { item in
                HStack(spacing: 14) {
                    AsyncImage(url: item.imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(AppColors.surfaceMedium)
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.name)
                            .font(.system(size: 16, weight: .bold))
                        Text("\(viewModel.currencySymbol)\(item.price, specifier: "%.0f") × \(item.quantity)")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Added by \(item.addedByUserId.user?.name ?? "Member")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.secondaryText)
                    }

                    Spacer()

                    Button(role: .destructive) {
                        Task { await viewModel.removeCartItem(item) }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(AppColors.pureWhite)
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
        }
    }
}
