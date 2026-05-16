// RegistryListView.swift
// WSHackathonApp

import SwiftUI

struct RegistryListView: View {

    @StateObject private var viewModel = RegistryListViewModel()
    @State private var selectedRegistry: RegistryModel?
    @State private var showJoinSheet = false
    @State private var showCreateActionSheet = false
    @State private var showCreateEventCover = false
    @State private var showCreateGiftingCover = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "0F1923"), Color(hex: "1C2B3A")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    filterPills
                    content
                }
            }
            .navigationTitle("Registry")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showJoinSheet = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .foregroundStyle(.white)
                        }
                        Button {
                            showCreateActionSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color(hex: "F2A623"))
                        }
                    }
                }
            }
            .confirmationDialog("Create a Registry", isPresented: $showCreateActionSheet, titleVisibility: .visible) {
                Button("Create for an Event") { showCreateEventCover = true }
                Button("Create for Gifting") { showCreateGiftingCover = true }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showJoinSheet) {
                JoinRegistrySheet(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showCreateEventCover) {
                CreateRegistryView(registryType: .event) { newRegistry in
                    viewModel.appendRegistry(newRegistry)
                }
            }
            .fullScreenCover(isPresented: $showCreateGiftingCover) {
                CreateRegistryView(registryType: .gifting) { newRegistry in
                    viewModel.appendRegistry(newRegistry)
                }
            }
            .navigationDestination(for: RegistryModel.self) { registry in
                RegistryDetailView(registry: registry) { id in
                    viewModel.removeRegistry(id: id)
                }
            }
        }
        .task {
            await viewModel.loadRegistries()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.5))
            TextField("Search registries…", text: $viewModel.searchText)
                .foregroundStyle(.white)
                .tint(Color(hex: "F2A623"))
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Filter Pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RegistryFilter.allCases) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView()
                .tint(Color(hex: "F2A623"))
                .scaleEffect(1.4)
            Spacer()
        } else if viewModel.filteredRegistries.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredRegistries) { registry in
                        NavigationLink(value: registry) {
                            if registry.registryType == .event {
                                EventRegistryCard(registry: registry)
                            } else {
                                GiftingRegistryCard(registry: registry)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "list.clipboard")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: "F2A623").opacity(0.6))
            VStack(spacing: 8) {
                Text("No Registries Yet")
                    .font(.title2).fontWeight(.bold).foregroundStyle(.white)
                Text("Tap + to create your first registry\nor join one with a code.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(isSelected ? Color(hex: "0F1923") : .white)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? Color(hex: "F2A623")
                        : Color.white.opacity(0.12),
                    in: Capsule()
                )
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Event Registry Card

struct EventRegistryCard: View {
    let registry: RegistryModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Card gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1B2B4B"), Color(hex: "0D1B2E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 12, y: 6)

            // "EVENT" badge
            Text("EVENT")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(hex: "F2A623"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "F2A623").opacity(0.15), in: Capsule())
                .padding(16)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    // Event icon
                    Image(systemName: registry.eventType?.sfSymbol ?? "gift.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: "F2A623"))
                        .frame(width: 52, height: 52)
                        .background(Color(hex: "F2A623").opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(registry.name)
                            .font(.headline).fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(registry.eventType?.displayName ?? "Event")
                            .font(.caption).foregroundStyle(.white.opacity(0.55))
                    }
                }

                Text(registry.displayEventDate)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.leading, 4)

                Divider().background(.white.opacity(0.1))

                budgetPill
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
    }

    private var budgetPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "banknote")
                .font(.caption2)
                .foregroundStyle(Color(hex: "F2A623"))
            if let snap = registry.budgetSnapshot, snap.totalBudget > 0 {
                Text("\(registry.currencySymbol)\(Int(snap.remainingAmount)) remaining")
                    .font(.caption2).foregroundStyle(.white.opacity(0.7))
            } else {
                Text("No budget set")
                    .font(.caption2).foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}

// MARK: - Gifting Registry Card

struct GiftingRegistryCard: View {
    let registry: RegistryModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Warm gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "4A1025"), Color(hex: "2C0A18")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "4A1025").opacity(0.5), radius: 12, y: 6)

            // Background gift icon
            Image(systemName: "giftcard.fill")
                .font(.system(size: 90))
                .foregroundStyle(.white.opacity(0.05))
                .offset(x: 20, y: -10)

            // "GIFTING" badge
            Text("GIFTING")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(hex: "E8593C"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "E8593C").opacity(0.15), in: Capsule())
                .padding(16)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: "E8593C"))
                        .frame(width: 52, height: 52)
                        .background(Color(hex: "E8593C").opacity(0.15), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(registry.name)
                            .font(.headline).fontWeight(.bold)
                            .foregroundStyle(.white).lineLimit(1)
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(registry.memberCount) contributor\(registry.memberCount == 1 ? "" : "s")")
                                .font(.caption)
                        }
                        .foregroundStyle(.white.opacity(0.55))
                    }
                }

                Text(registry.displayEventDate)
                    .font(.caption2).foregroundStyle(.white.opacity(0.45)).padding(.leading, 4)

                Divider().background(.white.opacity(0.1))

                budgetPill
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
    }

    private var budgetPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "banknote")
                .font(.caption2)
                .foregroundStyle(Color(hex: "E8593C"))
            if let snap = registry.budgetSnapshot, snap.totalBudget > 0 {
                Text("\(registry.currencySymbol)\(Int(snap.remainingAmount)) remaining")
                    .font(.caption2).foregroundStyle(.white.opacity(0.7))
            } else {
                Text("No budget set")
                    .font(.caption2).foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
