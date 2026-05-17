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
        .clipShape(RoundedRectangle(cornerRadius: 25))
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
                    .foregroundStyle(Color.black)
                Text("No registries match your search")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.primary)
                Text("Create a new registry or join one with a code.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemBackground))
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
                .padding(.horizontal, 16)
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
                .foregroundStyle(Color.primary)

            TextField("6-character code", text: $viewModel.joinCode)
                .textInputAutocapitalization(.characters)
                .onChange(of: viewModel.joinCode) { _, _ in
                    Task { await viewModel.previewJoinRegistry() }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 25))

            if let preview = viewModel.joinPreview {
                VStack(alignment: .leading, spacing: 8) {
                    Text(preview.name)
                        .font(.system(size: 18, weight: .bold))
                    Text(preview.eventType.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground))
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
                .background(Color(uiColor: .secondarySystemBackground))
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
                .background(Color.black)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.joinCode.count != 6)

            Spacer()
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
    }
}

private struct EventRegistryCard: View {
    let registry: Registry

    private let cornerRadius: CGFloat = 25
    private let contentInset: CGFloat = 36
    private let navyBlue = Color(red: 0.1, green: 0.2, blue: 0.5)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white)

            EventIntricateBorder(color: navyBlue)
                .padding(1.25)

            VStack(alignment: .leading, spacing: 8) {
                Text(registry.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.primary)
                Text(registry.eventType.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Text(registry.eventDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
            }
            .padding(contentInset)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5)
        )
    }
}

private struct EventIntricateBorder: View {
    let color: Color
    
    private let lineWidth: CGFloat = 2.5
    private let innerGap: CGFloat = 3
    
    var body: some View {
        ZStack {
            // Outer frame
            Rectangle()
                .stroke(color, lineWidth: lineWidth)
            
            // Inner frame
            Rectangle()
                .stroke(color, lineWidth: lineWidth)
                .padding(lineWidth + innerGap)
            
            // Corners overlay
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    CornerKnot(color: color, lineWidth: lineWidth, innerGap: innerGap)
                    Spacer(minLength: 0)
                    CornerKnot(color: color, lineWidth: lineWidth, innerGap: innerGap)
                        .rotationEffect(.degrees(90))
                }
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    CornerKnot(color: color, lineWidth: lineWidth, innerGap: innerGap)
                        .rotationEffect(.degrees(-90))
                    Spacer(minLength: 0)
                    CornerKnot(color: color, lineWidth: lineWidth, innerGap: innerGap)
                        .rotationEffect(.degrees(180))
                }
            }
        }
    }
}

private struct CornerKnot: View {
    let color: Color
    let lineWidth: CGFloat
    let innerGap: CGFloat
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background mask
            Rectangle()
                .fill(Color.white)
                .frame(width: 24, height: 24)
            
            // Knot Path
            Path { p in
                // Outer loop
                p.move(to: CGPoint(x: 24, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 24))
                
                let i = lineWidth + innerGap
                
                // Inner loop
                p.move(to: CGPoint(x: 24, y: i))
                p.addLine(to: CGPoint(x: i, y: i))
                p.addLine(to: CGPoint(x: i, y: 24))
                
                // Interlocking square
                let sq = i + lineWidth + innerGap
                p.move(to: CGPoint(x: 0, y: sq))
                p.addLine(to: CGPoint(x: sq, y: sq))
                p.addLine(to: CGPoint(x: sq, y: 0))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .square, lineJoin: .miter))
        }
        .frame(width: 24, height: 24)
    }
}

private struct GiftingRegistryCard: View {
    let registry: Registry

    private let cornerRadius: CGFloat = 25
    private let ribbonColor = Color(red: 0.85, green: 0.15, blue: 0.15)
    private let ribbonWidth: CGFloat = 8
    private let verticalRibbonOffset: CGFloat = 25
    private let horizontalRibbonOffset: CGFloat = 25

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white)

            // Horizontal Ribbon
            VStack(spacing: 0) {
                Rectangle()
                    .fill(ribbonColor)
                    .frame(height: ribbonWidth)
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                    .padding(.top, horizontalRibbonOffset)
                Spacer(minLength: 0)
            }

            // Vertical Ribbon
            HStack(spacing: 0) {
                Rectangle()
                    .fill(ribbonColor)
                    .frame(width: ribbonWidth)
                    .shadow(color: .black.opacity(0.15), radius: 3, x: 2)
                    .padding(.leading, verticalRibbonOffset)
                Spacer(minLength: 0)
            }

            // Knot / Bow
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ZStack {
                        Capsule().fill(ribbonColor).frame(width: 32, height: 6).rotationEffect(.degrees(0))
                        Capsule().fill(ribbonColor).frame(width: 32, height: 6).rotationEffect(.degrees(45))
                        Capsule().fill(ribbonColor).frame(width: 32, height: 6).rotationEffect(.degrees(90))
                        Capsule().fill(ribbonColor).frame(width: 32, height: 6).rotationEffect(.degrees(135))
                        Circle().fill(Color(red: 0.8, green: 0.1, blue: 0.1)).frame(width: 10, height: 10)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .frame(width: ribbonWidth, height: ribbonWidth)
                    .padding(.leading, verticalRibbonOffset)
                    .padding(.top, horizontalRibbonOffset)
                    
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }

            // Text Content (Left aligned with good breathing space)
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: horizontalRibbonOffset + ribbonWidth)
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: verticalRibbonOffset + ribbonWidth)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(registry.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        Text(registry.eventDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.primary)
                        
                        Text(registry.collaboratorCountText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5)
        )
    }
}
