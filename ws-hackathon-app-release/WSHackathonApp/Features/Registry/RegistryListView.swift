//
//  RegistryListView.swift
//  WSHackathonApp
//

import SwiftUI

struct RegistryListView: View {
    @StateObject private var viewModel = RegistryListViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                searchBar
                filterPills
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .background(AppColors.surfaceLight.ignoresSafeArea())
            .navigationTitle("Registry")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .sheet(isPresented: $viewModel.isPresentingJoinRegistry) {
                joinRegistrySheet
                    .presentationDetents([.medium])
            }
            .fullScreenCover(isPresented: $viewModel.isPresentingCreateRegistry, onDismiss: {
                Task { await viewModel.loadRegistries() }
            }) {
                CreateRegistryView(registryType: viewModel.createRegistryType)
            }
            .task {
                await viewModel.loadRegistries()
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.secondaryText)
            TextField("Search registries", text: $viewModel.searchText)
                .textInputAutocapitalization(.words)
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.mutedText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RegistryFilter.allCases, id: \.self) { filter in
                    Button {
                        viewModel.filter = filter
                    } label: {
                        Text(filter.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(viewModel.filter == filter ? Color.white : AppColors.primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(viewModel.filter == filter ? AppColors.alwaysBlack : AppColors.pureWhite)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView()
            Spacer()
        } else if viewModel.filteredRegistries.isEmpty {
            Spacer()
            VStack(spacing: 14) {
                Image(systemName: "giftcard.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.accent)
                Text("No registries match your search")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                Text("Create a new registry or join one with a code.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(AppColors.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredRegistries) { registry in
                        NavigationLink(destination: RegistryDetailView(registryID: registry.id)) {
                            if registry.registryType == .event {
                                EventRegistryCard(registry: registry)
                            } else {
                                GiftingRegistryCard(registry: registry)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                viewModel.isPresentingJoinRegistry = true
            } label: {
                Image(systemName: "person.badge.plus")
                    .foregroundStyle(AppColors.primaryText)
            }

            Menu {
                Button("Create for Event") { viewModel.prepareCreate(.event) }
                Button("Create for Gifting") { viewModel.prepareCreate(.gifting) }
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(AppColors.primaryText)
            }
        }
    }

    private var joinRegistrySheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Join a Registry")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColors.primaryText)

            TextField("6-character code", text: $viewModel.joinCode)
                .textInputAutocapitalization(.characters)
                .onChange(of: viewModel.joinCode) { _, _ in
                    Task { await viewModel.previewJoinRegistry() }
                }
                .padding()
                .background(AppColors.surfaceMedium)
                .clipShape(RoundedRectangle(cornerRadius: 25))

            if let preview = viewModel.joinPreview {
                VStack(alignment: .leading, spacing: 8) {
                    Text(preview.name)
                        .font(.system(size: 18, weight: .bold))
                    Text(preview.eventType.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.pureWhite)
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }

            if viewModel.joinPreview?.registryType == .gifting,
               viewModel.joinPreview?.giftingDetails?.splitType == .dutch,
               viewModel.joinPreview?.giftingDetails?.budgetStatus == .pending {
                TextField(
                    "Your budget contribution (\(viewModel.joinPreview?.currency.symbol ?? "$"))",
                    text: $viewModel.joinContributionText
                )
                .keyboardType(.decimalPad)
                .padding()
                .background(AppColors.surfaceMedium)
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }

            if let joinErrorMessage = viewModel.joinErrorMessage {
                Text(joinErrorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    do {
                        try await viewModel.joinRegistry(code: viewModel.joinCode)
                    } catch {
                        viewModel.joinErrorMessage = error.localizedDescription
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isJoining {
                        ProgressView().tint(.white)
                    } else {
                        Text("Join")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(AppColors.alwaysBlack)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.joinCode.count != 6)

            Spacer()
        }
        .padding(20)
        .background(AppColors.surfaceLight)
    }
}

private struct EventRegistryCard: View {
    let registry: Registry

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                Label {
                    EmptyView()
                } icon: {
                    Image(systemName: registry.eventType.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                Spacer()

                badge(title: "EVENT")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(registry.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Text(registry.eventType.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                Text(registry.eventDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }

            budgetPill
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: "#0E1628"), Color(hex: "#273247")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    private var budgetPill: some View {
        Label {
            Text("\(registry.currency.symbol)\(Int(registry.budgetSnapshot.remainingAmount)) remaining")
                .font(.system(size: 14, weight: .semibold))
        } icon: {
            Image(systemName: "piggybank.fill")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
    }

    private func badge(title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.14))
            .clipShape(Capsule())
    }
}

private struct GiftingRegistryCard: View {
    let registry: Registry

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#5F1423"), Color(hex: "#A53549")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "gift.fill")
                .font(.system(size: 92, weight: .black))
                .foregroundStyle(Color.white.opacity(0.12))
                .offset(x: 20, y: 10)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    ribbonDecoration
                    Spacer()
                    badge(title: "GIFTING")
                }

                Text(registry.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 6) {
                    Text(registry.eventDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                    Text(registry.collaboratorCountText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                Label {
                    Text("\(registry.currency.symbol)\(Int(registry.budgetSnapshot.remainingAmount)) remaining")
                        .font(.system(size: 14, weight: .semibold))
                } icon: {
                    Image(systemName: "piggybank.fill")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.14))
                .clipShape(Capsule())
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var ribbonDecoration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.16))
                .frame(width: 58, height: 58)
            Path { path in
                path.move(to: CGPoint(x: 29, y: 6))
                path.addLine(to: CGPoint(x: 29, y: 52))
                path.move(to: CGPoint(x: 6, y: 29))
                path.addLine(to: CGPoint(x: 52, y: 29))
            }
            .stroke(Color.white.opacity(0.8), lineWidth: 5)
        }
    }

    private func badge(title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.14))
            .clipShape(Capsule())
    }
}
