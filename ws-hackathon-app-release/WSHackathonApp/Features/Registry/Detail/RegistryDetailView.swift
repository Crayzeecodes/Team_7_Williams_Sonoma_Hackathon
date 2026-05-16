// RegistryDetailView.swift
// WSHackathonApp

import SwiftUI

struct RegistryDetailView: View {
    @StateObject private var viewModel: RegistryDetailViewModel
    let onLeft: (String) -> Void

    init(registry: RegistryModel, onLeft: @escaping (String) -> Void) {
        _viewModel = StateObject(wrappedValue: RegistryDetailViewModel(registry: registry))
        self.onLeft = onLeft
    }

    var body: some View {
        ZStack {
            Color(hex: "0F1923").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerBanner
                    VStack(spacing: 24) {
                        piggyBankSection
                        joinCodeCard
                        if !viewModel.aiSuggestions.isEmpty {
                            aiSuggestionsSection
                        }
                        cartSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(viewModel.registry.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showCollaboratorsSheet = true
                } label: {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(Color(hex: "F2A623"))
                }
            }
        }
        .sheet(isPresented: $viewModel.showCollaboratorsSheet) {
            CollaboratorsView(
                registryId: viewModel.registry.id,
                adminId: viewModel.registry.adminId ?? "",
                currentUserId: "demo-user-001",
                members: $viewModel.members
            ) {
                onLeft(viewModel.registry.id)
            }
        }
        .task {
            await viewModel.loadDetail()
            if viewModel.aiSuggestions.isEmpty {
                await viewModel.fetchSuggestions()
            }
            viewModel.connectSocket()
        }
        .onDisappear {
            viewModel.disconnectSocket()
        }
        .overlay(alignment: .bottom) {
            if let err = viewModel.error {
                Text(err)
                    .font(.caption).foregroundStyle(.white)
                    .padding(12)
                    .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: viewModel.registry.registryType == .event
                    ? [Color(hex: "1B2B4B"), Color(hex: "0D1B2E")]
                    : [Color(hex: "4A1025"), Color(hex: "2C0A18")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 160)

            Image(systemName: viewModel.registry.eventType?.sfSymbol ?? "gift.fill")
                .font(.system(size: 90))
                .foregroundStyle(.white.opacity(0.06))
                .offset(x: 230, y: -10)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.registry.registryType == .event ? "EVENT" : "GIFTING")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(viewModel.registry.registryType == .event ? Color(hex: "F2A623") : Color(hex: "E8593C"))
                    .textCase(.uppercase)
                Text(viewModel.registry.eventType?.displayName ?? "Registry")
                    .font(.caption).foregroundStyle(.white.opacity(0.55))
                Text(viewModel.registry.displayEventDate)
                    .font(.caption2).foregroundStyle(.white.opacity(0.4))
            }
            .padding(20)
        }
    }

    // MARK: - Piggy Bank Section

    private var piggyBankSection: some View {
        VStack(spacing: 0) {
            PiggyBankView(
                fillLevel: viewModel.budgetSnapshot.fillLevel,
                totalBudget: viewModel.budgetSnapshot.totalBudget,
                remainingAmount: viewModel.budgetSnapshot.remainingAmount,
                currencySymbol: viewModel.currencySymbol
            )
            .id(viewModel.budgetAnimationTrigger)
        }
        .padding(20)
        .background(Color(hex: "1B2B4B").opacity(0.6), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.08)))
    }

    // MARK: - Join Code Card

    private var joinCodeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Share Code").font(.caption).foregroundStyle(.white.opacity(0.5))
                Text(viewModel.joinCode)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "F2A623"))
            }
            Spacer()
            Button {
                UIPasteboard.general.string = viewModel.joinCode
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.title3)
                    .foregroundStyle(Color(hex: "F2A623"))
            }
        }
        .padding(16)
        .background(Color(hex: "1B2B4B").opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.08)))
    }

    // MARK: - AI Suggestions Section

    private var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Suggestions", systemImage: "sparkles")
                    .font(.headline).fontWeight(.bold).foregroundStyle(.white)
                Spacer()
                Button {
                    Task { await viewModel.fetchSuggestions() }
                } label: {
                    if viewModel.isLoadingSuggestions {
                        ProgressView().tint(Color(hex: "F2A623"))
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color(hex: "F2A623"))
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.aiSuggestions) { suggestion in
                        AiSuggestionCard(suggestion: suggestion) {
                            Task { await viewModel.addSuggestionToCart(suggestion) }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Cart Section

    private var cartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared Cart")
                .font(.headline).fontWeight(.bold).foregroundStyle(.white)

            if viewModel.cartItems.isEmpty {
                Text("No items yet. Add products from AI suggestions or browse the shop.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.4))
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(viewModel.cartItems) { item in
                    RegistryCartItemRow(item: item) {
                        Task { await viewModel.removeCartItem(item) }
                    }
                }
            }
        }
    }
}

// MARK: - AI Suggestion Card

private struct AiSuggestionCard: View {
    let suggestion: AiSuggestion
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product image
            AsyncImage(url: suggestion.product?.displayImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.white.opacity(0.08)
                    .overlay(Image(systemName: "photo").foregroundStyle(.white.opacity(0.3)))
            }
            .frame(width: 140, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Name
            Text(suggestion.product?.name ?? "Product \(suggestion.productId)")
                .font(.caption).fontWeight(.semibold).foregroundStyle(.white)
                .lineLimit(2).frame(width: 140, alignment: .leading)

            // Price
            if let price = suggestion.product?.price {
                Text("$\(String(format: "%.2f", price))")
                    .font(.caption).foregroundStyle(Color(hex: "F2A623"))
            }

            // Score bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.1)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: "F2A623"))
                        .frame(width: geo.size.width * suggestion.score, height: 4)
                }
            }
            .frame(height: 4).frame(width: 140)

            // Reasoning
            Text(suggestion.reasoning)
                .font(.system(size: 9)).foregroundStyle(.white.opacity(0.45))
                .lineLimit(2).frame(width: 140, alignment: .leading)

            // Add button
            Button(action: onAdd) {
                Label("Add to Cart", systemImage: "plus.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "0F1923"))
                    .frame(width: 140)
                    .padding(.vertical, 8)
                    .background(Color(hex: "F2A623"), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(hex: "1B2B4B").opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.08)))
    }
}

// MARK: - Cart Item Row

private struct RegistryCartItemRow: View {
    let item: CartItemModel
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: item.displayImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.white.opacity(0.08)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white).lineLimit(2)
                HStack(spacing: 6) {
                    Text("$\(String(format: "%.2f", item.price * Double(item.quantity)))")
                        .font(.caption).foregroundStyle(Color(hex: "F2A623"))
                    Text("×\(item.quantity)")
                        .font(.caption2).foregroundStyle(.white.opacity(0.45))
                }
                // Added by (initials)
                HStack(spacing: 4) {
                    ZStack {
                        Circle().fill(Color(hex: "F2A623").opacity(0.2)).frame(width: 16, height: 16)
                        Text(String(item.addedByUserId.prefix(2)).uppercased())
                            .font(.system(size: 7, weight: .bold)).foregroundStyle(Color(hex: "F2A623"))
                    }
                    if let src = item.source {
                        Text(src == .ai ? "AI pick" : "Manual")
                            .font(.system(size: 9)).foregroundStyle(.white.opacity(0.35))
                    }
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
            }
        }
        .padding(12)
        .background(Color(hex: "1B2B4B").opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.06)))
    }
}
