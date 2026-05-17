//
//  RegistryDetailView.swift
//  WSHackathonApp
//

import SwiftUI

struct RegistryDetailView: View {
    @StateObject private var viewModel: RegistryDetailViewModel
    @State private var isEditingPoll = false
    @State private var isShowingAllSuggestions = false

    init(registryID: String) {
        _viewModel = StateObject(wrappedValue: RegistryDetailViewModel(registryID: registryID))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 34) {
                if viewModel.registry != nil {
                    PiggyBankView(
                        budgetSnapshot: viewModel.budgetSnapshot,
                        currencySymbol: viewModel.currencySymbol,
                        trigger: viewModel.coinAnimationTrigger
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    aiSuggestionsSection
                    sharedCartSection
                    pollsSection
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
            .padding(.bottom, 124)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if viewModel.registry != nil {
                SlidingCheckoutButton {
                    // Checkout flow can be connected here.
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(viewModel.registry?.name ?? "Registry")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                    if let date = viewModel.registry?.eventDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
            }
            
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
        .sheet(isPresented: $viewModel.isPresentingPlannerEditor) {
            RegistryPlannerEditorView(
                answers: viewModel.plannerAnswers,
                isSaving: viewModel.isSavingPlannerAnswers
            ) { answers in
                Task { await viewModel.savePlannerAnswers(answers) }
            }
        }
        .navigationDestination(isPresented: $isShowingAllSuggestions) {
            RegistrySuggestionsCategoryView(
                products: viewModel.suggestedProducts,
                currencySymbol: viewModel.currencySymbol
            )
        }
        .task {
            await viewModel.load()
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }

    private func header(_ registry: Registry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(registry.creatorName.components(separatedBy: " ").map { String($0.prefix(1)) }.joined().prefix(2).capitalized)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.secondaryText)
                Spacer()
            }
            
            Text(registry.name)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
            
            Text("Join code: \(registry.joinCode)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.accent)
            
            Text(registry.eventDate.formatted(date: .complete, time: .omitted))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    private var aiSuggestionsSection: some View {
        sectionBlock(
            title: "AI Suggestions",
            trailing: {
                Button("See all") {
                    isShowingAllSuggestions = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.accent)
            }
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Button {
                    viewModel.isPresentingPlannerEditor = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit AI answers")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Update the questions behind these recommendations.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                    }
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                }
                .buttonStyle(.plain)
                .registryCardStyle()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.suggestedProducts) { product in
                            suggestedProductCard(product)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                .padding(.horizontal, -16)
            }
        }
    }

    private func suggestedProductCard(_ product: RegistryProduct) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: 180, height: 160)
                    .overlay(
                        AsyncImage(url: product.primaryImageURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "photo")
                                .font(.system(size: 26, weight: .ultraLight))
                                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        }
                    )
                    .clipped()

                Button {
                    Task { await viewModel.addSuggestedProductToCart(product) }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .systemBackground).opacity(0.92))
                            .frame(width: 34, height: 34)
                        if viewModel.addingProductIDs.contains(product.id) {
                            ProgressView()
                                .scaleEffect(0.75)
                        } else {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
                .padding(8)
                .accessibilityLabel("Add \(product.name) to shared cart")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.category.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.8)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)

                Text(product.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                    .frame(minHeight: 36, alignment: .topLeading)

                Text("\(viewModel.currencySymbol)\(product.price, specifier: "%.2f")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary)
            }
            .padding(10)
            .frame(width: 180, alignment: .leading)
        }
        .frame(width: 180)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private var sharedCartSection: some View {
        sectionBlock(title: "Shared Cart") {
            VStack(alignment: .leading, spacing: 12) {
                if viewModel.cartItems.isEmpty {
                    Text("No products added yet.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
                } else {
                    ForEach(viewModel.cartItems) { item in
                        HStack(spacing: 14) {
                            AsyncImage(url: item.imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Rectangle().fill(Color(uiColor: .secondarySystemBackground))
                            }
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .lineLimit(2)
                                Text(item.source == .ai ? "AI Suggestions" : "Shared Cart")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                                Text("\(viewModel.currencySymbol)\(item.price * Double(item.quantity), specifier: "%.2f")")
                                    .font(.system(size: 16, weight: .bold))
                                Text("\(viewModel.currencySymbol)\(item.price, specifier: "%.2f") each")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                            }

                            Spacer()

                            HStack(spacing: 14) {
                                Button {
                                    Task { await viewModel.decrementCartItem(item) }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(Color.primary)
                                        .frame(width: 34, height: 34)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                        .clipShape(Circle())
                                }
                                .accessibilityLabel("Decrease quantity for \(item.name)")

                                Text("\(item.quantity)")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(minWidth: 18)

                                Button {
                                    Task { await viewModel.incrementCartItem(item) }
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(Color.primary)
                                        .frame(width: 34, height: 34)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                        .clipShape(Circle())
                                }
                                .accessibilityLabel("Increase quantity for \(item.name)")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .registryCardStyle()
                    }                    
                }
            }
        }
    }

    @ViewBuilder
    private var pollsSection: some View {
        if viewModel.registry?.registryType == .gifting {
            sectionBlock(
                title: "Polls",
                trailing: {
                    if viewModel.activePoll == nil {
                        Button {
                            Task { await viewModel.createPoll() }
                        } label: {
                            Label("Create Poll", systemImage: "chart.bar.doc.horizontal")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .disabled(viewModel.cartItems.isEmpty)
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                isEditingPoll.toggle()
                            }
                        } label: {
                            Image(systemName: isEditingPoll ? "checkmark" : "pencil")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.primary)
                        }
                        .accessibilityLabel(isEditingPoll ? "Done editing poll" : "Edit poll")
                    }
                }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.activePoll == nil {
                        Text("Create a poll from the shared cart once products have been added.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
                    } else if let poll = viewModel.activePoll {
                        pollCard(poll)

                        if isEditingPoll {
                            pollEditor
                        }
                    }
                }
            }
        }
    }

    private var pollEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Cart Items")
                .font(.system(size: 16, weight: .bold))

            if viewModel.pollAddableCartItems.isEmpty {
                Text("All shared cart products are already in this poll.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.secondary)
            } else {
                ForEach(viewModel.pollAddableCartItems) { item in
                    Button {
                        Task { await viewModel.addToPoll(item) }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.primary)
                            Text(item.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.primary)
                                .lineLimit(2)
                            Spacer()
                        }
                        .padding(12)
                        .registryCardStyle(cornerRadius: 25)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add \(item.name) to poll")
                }
            }
        }
        .padding(14)
        .registryCardStyle()
    }

    private func pollCard(_ poll: RegistryPoll) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(poll.question)
                .font(.system(size: 17, weight: .bold))

            ForEach(poll.options, id: \.productId) { option in
                Button {
                    Task { await viewModel.vote(in: poll, productId: option.productId) }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: selectedProductId(for: poll) == option.productId ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(Color.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cartItemName(for: option.productId))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.primary)
                                .lineLimit(2)
                            Text("\(option.votes.count) vote\(option.votes.count == 1 ? "" : "s")")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Vote for \(cartItemName(for: option.productId))")
            }
        }
        .padding(14)
        .registryCardStyle()
    }

    private func cartItemName(for productId: String) -> String {
        viewModel.cartItems.first(where: { $0.productId == productId })?.name ?? "Product"
    }

    private func selectedProductId(for poll: RegistryPoll) -> String? {
        viewModel.selectedPollProductIDs[poll.id]
    }

    private func sectionBlock<Content: View, Trailing: View>(
        title: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .lastTextBaseline) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.primary)
                Spacer()
                trailing()
            }

            content()
        }
        .padding(.horizontal, 16)
    }
}

private extension View {
    func registryCardStyle(cornerRadius: CGFloat = 25) -> some View {
        self
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}
