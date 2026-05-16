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
            .padding(.top, 10)
            .background(Color(uiColor: .systemBackground))
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
                .font(.system(size: 16))
                .foregroundStyle(Color.secondary)
            TextField("Search registries", text: $viewModel.searchText)
                .font(.system(size: 16))
                .foregroundStyle(Color.primary)
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
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
                            .foregroundStyle(viewModel.filter == filter ? Color.white : Color.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(viewModel.filter == filter ? Color.black : Color(uiColor: .secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
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
                    .font(.system(size: 19))
                    .foregroundStyle(Color.primary)
            }

            Menu {
                Button("Create for Event") { viewModel.prepareCreate(.event) }
                Button("Create for Gifting") { viewModel.prepareCreate(.gifting) }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 19))
                    .foregroundStyle(Color.primary)
            }
            
            // Profile circle to match ShopView
            Button(action: { /* navManager.showProfile = true */ }) {
                Circle()
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Text("WS") // Hardcoded for now or fetch from user manager
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary)
                    )
                    .overlay(Circle().stroke(Color(uiColor: .separator), lineWidth: 0.5))
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
        ZStack {
            // Thinner Ribbon border
            RoundedRectangle(cornerRadius: 25)
                .stroke(AppColors.accent, lineWidth: 3) // Thinner (was 6)
                .padding(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(AppColors.accent, lineWidth: 1) // Thinner (was 2)
                        .padding(-2)
                )

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: registry.eventType.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 52, height: 52)
                        .background(AppColors.surfaceMedium)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(registry.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                    Text(registry.eventType.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                    Text(registry.eventDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                }
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}

private struct GiftingRegistryCard: View {
    let registry: Registry

    var body: some View {
        ZStack {
            // Thinner Cross Ribbon
            VStack {
                Rectangle()
                    .fill(AppColors.accent)
                    .frame(width: 12) // Thinner (was 24)
                    .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 60)

            HStack {
                Rectangle()
                    .fill(AppColors.accent)
                    .frame(height: 12) // Thinner (was 24)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 50)

            // Ribbon Bow (Circle for simplicity, can be more complex)
            Circle()
                .fill(AppColors.accent)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "ribbon")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                )
                .offset(x: -UIScreen.main.bounds.width/2 + 72 + 60, y: -UIScreen.main.bounds.height/2 + 250) // Adjust offsets carefully
                // Actually easier to anchor to top leading of the intersection
            
            // Re-anchoring Bow
            VStack {
                HStack {
                    ZStack {
                        // Thinner Bow Loops
                        Circle()
                            .stroke(AppColors.accent, lineWidth: 4) // Thinner (was 8)
                            .frame(width: 34, height: 24)
                            .rotationEffect(.degrees(-35))
                            .offset(x: -16, y: -12)
                        
                        Circle()
                            .stroke(AppColors.accent, lineWidth: 4) // Thinner (was 8)
                            .frame(width: 34, height: 24)
                            .rotationEffect(.degrees(35))
                            .offset(x: 16, y: -12)
                        
                        // Center knot
                        Circle()
                            .fill(AppColors.accent)
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "gift.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 72, y: 62)
                    Spacer()
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 14) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(registry.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                    Text(registry.eventDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                    Text(registry.collaboratorCountText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(AppColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}
