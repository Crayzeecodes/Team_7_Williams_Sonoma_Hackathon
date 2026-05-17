//
//  RoomScanHistoryView.swift
//  WSHackathonApp
//
//  Displays the list of past room scans.
//

import SwiftUI

@available(iOS 18.0, *)
struct RoomScanHistoryView: View {
    @State private var historyRecords: [RoomScanHistoryRecord] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading history...")
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else if historyRecords.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No scan history yet.")
                        .font(.headline)
                    Text("Your past room scans will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                List(historyRecords) { record in
                    NavigationLink(destination: RoomScanHistoryDetailWrapper(record: record)) {
                        HStack(spacing: 16) {
                            if let firstImage = record.imageUrls.first, let url = URL(string: firstImage) {
                                CustomAsyncImage(url: url)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                                    .frame(width: 60, height: 60)
                                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(record.detectedStyle) \(record.roomType.capitalized)")
                                    .font(.headline)
                                Text(record.createdAt, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Scan History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadHistory()
        }
    }
    
    private func loadHistory() async {
        do {
            isLoading = true
            historyRecords = try await RoomScanHistoryService.shared.fetchHistory()
            isLoading = false
        } catch {
            errorMessage = "Failed to load history."
            isLoading = false
        }
    }
}

@available(iOS 18.0, *)
struct RoomScanHistoryDetailWrapper: View {
    let record: RoomScanHistoryRecord
    @State private var viewModel = RoomScanViewModel()
    @State private var isReady = false
    
    var body: some View {
        Group {
            if isReady {
                RoomResultsView(viewModel: viewModel)
            } else {
                ProgressView("Loading details...")
            }
        }
        .navigationTitle("Scan Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await setupViewModel()
        }
    }
    
    private func setupViewModel() async {
        // Construct the AI result object from history
        let result = RoomAnalysisResult(
            roomType: record.roomType,
            detectedStyle: record.detectedStyle,
            dominantColors: record.dominantColors,
            dominantMaterials: record.dominantMaterials,
            recommendedStyleTags: [],
            recommendedCategories: [], // We only need the products for the view
            priceMax: 0,
            sizePreference: "",
            reasoning: record.reasoning,
            negativeCategories: [],
            recommendedProducts: []
        )
        
        // Fetch the full products from WSService
        do {
            let allProducts = try await WSService.shared.fetchProducts()
            let matchedProducts = allProducts.filter { record.recommendedProductIds.contains($0.id.uuidString) }
            
            viewModel.analysisResult = result
            viewModel.recommendedProducts = matchedProducts
            viewModel.viewState = .results // Trick the view model
            
            isReady = true
        } catch {
            print("Error loading products for history: \\(error)")
        }
    }
}
