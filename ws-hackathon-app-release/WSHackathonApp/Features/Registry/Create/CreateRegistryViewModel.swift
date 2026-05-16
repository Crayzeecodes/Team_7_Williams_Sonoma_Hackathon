// CreateRegistryViewModel.swift
// WSHackathonApp

import Foundation
import Combine
import SwiftUI

@MainActor
final class CreateRegistryViewModel: ObservableObject {

    // MARK: - Step 1 (common)
    @Published var creatorName: String = ""
    @Published var eventName: String = ""
    @Published var selectedEventType: EventType = .birthday
    @Published var eventDate: Date = Date().addingTimeInterval(86400 * 30) // 30 days out

    // MARK: - Step 2A (event specific)
    @Published var plannerAnswers: [String] = Array(repeating: "", count: 5)
    @Published var currentQuestionIndex: Int = 0

    // MARK: - Budget screen
    @Published var currency: CurrencyInfo = .usd
    @Published var budgetText: String = ""
    @Published var isDetectingCurrency: Bool = false

    // MARK: - Step 2B (gifting specific)
    @Published var collaboratorCount: Int = 1
    @Published var splitType: SplitType = .split
    @Published var individualBudgetText: String = ""

    // MARK: - Submission state
    @Published var isSubmitting: Bool = false
    @Published var error: String?
    @Published var createdRegistry: RegistryModel?

    // MARK: - Constants
    let plannerQuestions = [
        "What is the primary purpose of this event?",
        "How many guests are you expecting?",
        "What is the overall vibe or theme?",
        "Are there specific product categories you'd like to focus on?",
        "Any items you'd like to avoid?"
    ]

    // MARK: - Validation

    var isStep1Valid: Bool {
        !creatorName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !eventName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var allQuestionsAnswered: Bool {
        plannerAnswers.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var currentAnswer: Binding<String> {
        Binding(
            get: { self.plannerAnswers[self.currentQuestionIndex] },
            set: { self.plannerAnswers[self.currentQuestionIndex] = $0 }
        )
    }

    var isLastQuestion: Bool {
        currentQuestionIndex == plannerQuestions.count - 1
    }

    var currentQuestion: String {
        plannerQuestions[currentQuestionIndex]
    }

    var budget: Double { Double(budgetText) ?? 0 }
    var individualBudget: Double { Double(individualBudgetText) ?? 0 }

    // MARK: - Detect currency

    func detectCurrency() async {
        isDetectingCurrency = true
        currency = await CurrencyDetectionService.shared.detectCurrency()
        isDetectingCurrency = false
    }

    // MARK: - Navigation

    func goToNextQuestion() {
        guard currentQuestionIndex < plannerQuestions.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentQuestionIndex += 1
        }
    }

    func goToPreviousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentQuestionIndex -= 1
        }
    }

    // MARK: - Submit Event Registry

    func submitEventRegistry() async {
        isSubmitting = true
        error = nil
        defer { isSubmitting = false }

        let dateStr = ISO8601DateFormatter().string(from: eventDate)
        let body = CreateRegistryRequest(
            name: eventName.trimmingCharacters(in: .whitespaces),
            registryType: RegistryType.event.rawValue,
            creatorName: creatorName.trimmingCharacters(in: .whitespaces),
            eventType: selectedEventType.rawValue,
            eventDate: dateStr,
            currency: currency,
            eventDetails: EventDetailsRequest(
                aiPlannerAnswers: plannerAnswers,
                targetBudget: budget,
                paymentSplitType: SplitType.split.rawValue
            ),
            giftingDetails: nil
        )

        do {
            createdRegistry = try await RegistryService.shared.create(body)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Submit Gifting Registry

    func submitGiftingRegistry() async {
        isSubmitting = true
        error = nil
        defer { isSubmitting = false }

        let dateStr = ISO8601DateFormatter().string(from: eventDate)
        let creatorBudget = splitType == .split ? budget : individualBudget
        let pooledBudget = splitType == .dutch ? individualBudget : budget

        let body = CreateRegistryRequest(
            name: eventName.trimmingCharacters(in: .whitespaces),
            registryType: RegistryType.gifting.rawValue,
            creatorName: creatorName.trimmingCharacters(in: .whitespaces),
            eventType: selectedEventType.rawValue,
            eventDate: dateStr,
            currency: currency,
            eventDetails: nil,
            giftingDetails: GiftingDetailsRequest(
                collaboratorCount: collaboratorCount,
                aiPlannerAnswers: plannerAnswers,
                splitType: splitType.rawValue,
                creatorBudget: creatorBudget,
                pooledBudget: pooledBudget
            )
        )

        do {
            createdRegistry = try await RegistryService.shared.create(body)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Trigger AI suggestions in background

    func triggerAISuggestions(for registryId: String) {
        Task {
            try? await RegistryService.shared.fetchSuggestions(registryId: registryId)
        }
    }
}
