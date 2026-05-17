//
//  RoomScanViewModel.swift
//  WSHackathonApp
//
//  ViewModel managing the entire Room Scan → Analysis → Results flow.
//

import Foundation
import UIKit

@Observable
class RoomScanViewModel {

    // MARK: - State
    enum ViewState: Equatable {
        case capturing
        case questioning
        case analyzing
        case results
        case error(String)
    }

    var capturedImages: [UIImage] = []
    var preferences = RoomScanPreferences()
    var currentQuestionIndex: Int = 0
    var analysisResult: RoomAnalysisResult? = nil
    var recommendedProducts: [WSProduct] = []
    var viewState: ViewState = .capturing
    private var analysisTask: Task<Void, Never>? = nil

    // MARK: - Computed
    var canAnalyze: Bool { !capturedImages.isEmpty }

    var currentQuestionTitle: String {
        switch currentQuestionIndex {
        case 0: return "What are you shopping for?"
        case 1: return "What size?"
        case 2: return "What's your budget?"
        case 3: return "Describe your style vibe"
        default: return ""
        }
    }

    var currentQuestionOptions: [String] {
        switch currentQuestionIndex {
        case 0: return RoomScanQuestions.categoryOptions
        case 1: return RoomScanQuestions.sizeOptions(for: preferences.category)
        case 2: return RoomScanQuestions.budgetOptions
        case 3: return RoomScanQuestions.styleOptions
        default: return []
        }
    }

    var currentAnswer: String {
        switch currentQuestionIndex {
        case 0: return preferences.category
        case 1: return preferences.size
        case 2:
            // Reverse-map budgetMax to display string
            switch preferences.budgetMax {
            case 100: return "Under $100"
            case 300: return "$100–$300"
            case 700: return "$300–$700"
            case 10_000: return "$700+"
            default: return ""
            }
        case 3: return preferences.styleVibe
        default: return ""
        }
    }

    // MARK: - Image Management
    func addImage(_ image: UIImage) {
        guard capturedImages.count < 4 else { return }
        capturedImages.append(image)
    }

    func removeImage(at index: Int) {
        guard capturedImages.indices.contains(index) else { return }
        capturedImages.remove(at: index)
    }

    func proceedToQuestions() {
        currentQuestionIndex = 0
        viewState = .questioning
    }

    // MARK: - Question Navigation
    func selectAnswer(_ answer: String) {
        switch currentQuestionIndex {
        case 0: preferences.category = answer
        case 1: preferences.size = answer
        case 2: preferences.budgetMax = RoomScanQuestions.budgetMax(for: answer)
        case 3: preferences.styleVibe = answer
        default: break
        }
    }

    func nextQuestion() {
        if currentQuestionIndex < 3 {
            currentQuestionIndex += 1
        } else {
            analyzeRoom()
        }
    }

    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        } else {
            viewState = .capturing
        }
    }

    // MARK: - Analysis
    func analyzeRoom() {
        viewState = .analyzing
        analysisTask = Task { @MainActor in
            do {
                let result = try await RoomScanService.shared.analyzeRoom(
                    images: capturedImages,
                    preferences: preferences
                )
                self.analysisResult = result
                // Fallback to empty array if decoding gives nil, though we expect RoomScanService to populate it locally.
                self.recommendedProducts = result.recommendedProducts ?? []
                self.viewState = .results
                
                // Save to history asynchronously in the background
                Task {
                    do {
                        try await RoomScanHistoryService.shared.saveScanResult(
                            images: capturedImages,
                            result: result,
                            recommendedProducts: self.recommendedProducts
                        )
                    } catch {
                        print("Failed to save scan history: \\(error)")
                    }
                }
            } catch is CancellationError {
                // Task was cancelled — do nothing
            } catch {
                self.viewState = .error(
                    error.localizedDescription
                )
            }
        }
    }

    func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
    }

    func retry() {
        analyzeRoom()
    }

    func reset() {
        capturedImages.removeAll()
        preferences = RoomScanPreferences()
        currentQuestionIndex = 0
        analysisResult = nil
        recommendedProducts.removeAll()
        viewState = .capturing
    }
}
