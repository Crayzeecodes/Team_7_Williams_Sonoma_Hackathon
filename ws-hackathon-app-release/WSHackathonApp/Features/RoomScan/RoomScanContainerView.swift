//
//  RoomScanContainerView.swift
//  WSHackathonApp
//
//  Container view managing the Room Scan state machine.
//  The entry view is shown inline, while the analysis flow is pushed via navigation.
//

import SwiftUI

@available(iOS 18.0, *)
struct RoomScanContainerView: View {
    @State private var viewModel = RoomScanViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                RoomScanEntryView(viewModel: viewModel)
                
                // Past AI Suggestions Cards
                PastAISuggestionsSection()
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { viewModel.viewState != .capturing },
            set: { if !$0 { viewModel.reset() } }
        )) {
            RoomScanFlowView(viewModel: viewModel)
        }
    }
}

@available(iOS 18.0, *)
struct RoomScanFlowView: View {
    @Bindable var viewModel: RoomScanViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .capturing:
                Color.clear // Fallback
            case .questioning:
                RoomPreferencesView(viewModel: viewModel)
            case .analyzing:
                RoomAnalysisLoadingView()
            case .results:
                RoomResultsView(viewModel: viewModel)
            case .error(let message):
                errorView(message)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(viewModel.viewState == .analyzing || viewModel.viewState == .results)
        .toolbar {
            if viewModel.viewState == .results {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { 
                        viewModel.reset()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundStyle(Color.primary)
                    }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.viewState == .analyzing)
        .onDisappear {
            if viewModel.viewState == .analyzing {
                viewModel.cancelAnalysis()
            }
        }
    }

    private var navigationTitle: String {
        switch viewModel.viewState {
        case .capturing:   return ""
        case .questioning: return "Preferences"
        case .analyzing:   return "Analysing"
        case .results:     return "Recommended for You"
        case .error:       return "Error"
        }
    }

    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))

            Text("Something went wrong")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.primary)

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 10) {
                Button(action: { viewModel.retry() }) {
                    Text("TRY AGAIN")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(WSPressButtonStyle())

                Button(action: { viewModel.reset() }) {
                    Text("START OVER")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                .buttonStyle(WSPressButtonStyle())
            }
            .padding(.horizontal, 16)

            Spacer()
        }
    }
}

// MARK: - Past AI Suggestions Section
@available(iOS 18.0, *)
struct PastAISuggestionsSection: View {
    @State private var records: [RoomScanHistoryRecord] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !records.isEmpty {
                Text("Past AI Suggestions")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                
                ForEach(records) { record in
                    NavigationLink(destination: RoomScanHistoryDetailWrapper(record: record)) {
                        HStack(spacing: 14) {
                            if let firstImage = record.imageUrls.first, let url = URL(string: firstImage) {
                                CustomAsyncImage(url: url)
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .tertiarySystemFill))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Image(systemName: "sparkles")
                                            .foregroundStyle(.secondary)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(record.detectedStyle) \(record.roomType.capitalized)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                                HStack(spacing: 8) {
                                    Label("\(record.recommendedProductIds.count) products", systemImage: "cube")
                                    Text("·")
                                    Text(record.createdAt, style: .date)
                                }
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        }
                        .padding(14)
                        .frame(minHeight: 80)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 16)
                }
            } else if !isLoading {
                // Show nothing if no history
            }
        }
        .padding(.bottom, 20)
        .task {
            do {
                records = try await RoomScanHistoryService.shared.fetchHistory()
            } catch {
                print("Failed to load AI history: \(error)")
            }
            isLoading = false
        }
    }
}
