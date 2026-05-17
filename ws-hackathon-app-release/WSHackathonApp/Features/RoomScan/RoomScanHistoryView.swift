
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
                    ZStack {
                        NavigationLink(destination: RoomScanHistoryDetailWrapper(record: record)) {
                            EmptyView()
                        }
                        .opacity(0)

                        HStack(spacing: 16) {
                            if let firstImage = record.imageUrls.first, let url = URL(string: firstImage) {
                                CustomAsyncImage(url: url)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                            } else {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color(uiColor: .tertiarySystemFill))
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
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
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

        let result = RoomAnalysisResult(
            roomType: record.roomType,
            detectedStyle: record.detectedStyle,
            dominantColors: record.dominantColors,
            dominantMaterials: record.dominantMaterials,
            recommendedStyleTags: [],
            recommendedCategories: [],
            priceMax: 0,
            sizePreference: "",
            reasoning: record.reasoning,
            negativeCategories: [],
            recommendedProducts: []
        )

        do {
            let allProducts = try await WSService.shared.fetchProducts()
            let recommendedIdsLower = Set(record.recommendedProductIds.map { $0.lowercased() })
            let matchedProducts = allProducts.filter { recommendedIdsLower.contains($0.id.uuidString.lowercased()) }

            viewModel.analysisResult = result
            viewModel.recommendedProducts = matchedProducts
            viewModel.scannedImageUrls = record.imageUrls
            viewModel.viewState = .results

            isReady = true
        } catch {
            print("Error loading products for history: \\(error)")
        }
    }
}
