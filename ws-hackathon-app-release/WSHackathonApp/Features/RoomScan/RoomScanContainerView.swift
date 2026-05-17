//
//  RoomScanContainerView.swift
//  WSHackathonApp
//
//  Container view managing the Room Scan state machine and sub-view transitions.
//

import SwiftUI

@available(iOS 18.0, *)
struct RoomScanContainerView: View {
    @State private var viewModel = RoomScanViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.viewState {
                case .capturing:
                    RoomScanEntryView(viewModel: viewModel)

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
            .toolbar {
                if viewModel.viewState == .capturing {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: RoomScanHistoryView()) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("History")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(Color.primary)
                        }
                    }
                } else if viewModel.viewState == .results {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { viewModel.reset() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("New Scan")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(Color.primary)
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.viewState == .analyzing)
        .onDisappear {
            viewModel.cancelAnalysis()
        }
    }

    private var navigationTitle: String {
        switch viewModel.viewState {
        case .capturing:   return "Room Scan"
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
