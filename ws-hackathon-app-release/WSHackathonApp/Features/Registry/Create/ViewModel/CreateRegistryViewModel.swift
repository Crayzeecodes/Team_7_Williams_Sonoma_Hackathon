//
//  CreateRegistryViewModel.swift
//  WSHackathonApp
//

import Foundation
import Combine
import Supabase

@MainActor
final class CreateRegistryViewModel: ObservableObject {
    enum CreationStep: Hashable {
        case giftingCollaborators
        case eventPlanner
        case giftingPlanner
        case eventBudget
        case giftingSplit
    }

    @Published var navigationPath: [CreationStep] = []
    @Published var creatorName: String = ""
    @Published var registryName: String = ""
    @Published var eventType: RegistryEventType = .birthday
    @Published var eventDate: Date = Date()
    @Published var collaboratorCount: Int = 1
    @Published var plannerAnswers: [RegistryPlannerAnswer] = [
        .init(question: "How many guests are you expecting?", answer: "", answers: [], options: ["< 10", "10-25", "25-50", "50-100", "100+", "Other"], allowsMultiple: true),
        .init(question: "What is the overall vibe or theme?", answer: "", answers: [], options: ["Modern", "Classic", "Rustic", "Bohemian", "Minimalist", "Colorful", "Other"], allowsMultiple: true),
        .init(question: "Are there any specific product categories you'd like to focus on?", answer: "", answers: [], options: ["Cookware", "Bakeware", "Electrics", "Tabletop", "Kitchen Tools", "Coffee & Tea", "Other"], allowsMultiple: true),
        .init(question: "Any items to avoid?", answer: "", answers: [], options: ["None", "Small Appliances", "Plastic items", "Fragile items", "Sharp objects", "Other"], allowsMultiple: true)
    ]
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedSplitType: RegistryPaymentSplitType = .split
    @Published var detectedCurrency: CurrencyInfo = .init(code: "USD", symbol: "$")
    @Published var selectedCurrency: CurrencyInfo = .init(code: "USD", symbol: "$")
    @Published var budgetText: String = ""
    @Published var yourBudgetText: String = ""
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var createdRegistry: Registry?
    @Published var shouldDismiss: Bool = false

    let registryType: RegistryType

    private let registryService: RegistryService
    private let currencyService: CurrencyDetectionService
    private let userManager: UserManager

    init(registryType: RegistryType, userManager: UserManager? = nil) {
        self.registryType = registryType
        self.registryService = .shared
        self.currencyService = .shared
        self.userManager = userManager ?? UserManager()
        
        // Pre-fill creator name
        if let user = self.userManager.currentUser {
            self.creatorName = "\(user.firstName) \(user.lastName)"
        }
    }

    var canContinueFromStepOne: Bool {
        !creatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !registryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        eventDate >= Calendar.current.startOfDay(for: Date())
    }

    var canAdvancePlanner: Bool {
        let current = plannerAnswers[currentQuestionIndex]
        let hasSelections = !current.answers.isEmpty
        let hasCustomAnswer = !current.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if isOtherSelected {
            return hasSelections && hasCustomAnswer
        }
        return hasSelections
    }

    var canSubmitEventBudget: Bool {
        parsedBudget > 0
    }

    var canSubmitGiftingBudget: Bool {
        switch selectedSplitType {
        case .split:
            return parsedBudget > 0
        case .dutch:
            return parsedYourBudget > 0
        }
    }

    var currencyOptions: [CurrencyInfo] {
        [
            .init(code: "INR", symbol: "₹"),
            .init(code: "USD", symbol: "$"),
            .init(code: "GBP", symbol: "£"),
            .init(code: "EUR", symbol: "€"),
            .init(code: "JPY", symbol: "¥"),
            .init(code: "AUD", symbol: "A$"),
            .init(code: "CAD", symbol: "CA$"),
            .init(code: "AED", symbol: "د.إ"),
            .init(code: "SGD", symbol: "S$"),
            .init(code: "CNY", symbol: "¥")
        ]
    }

    var currentQuestion: RegistryPlannerAnswer {
        plannerAnswers[currentQuestionIndex]
    }

    var shouldShowCustomAnswer: Bool {
        isOtherSelected
    }

    var parsedBudget: Double {
        Double(budgetText.filter { "0123456789.".contains($0) }) ?? 0
    }

    var parsedYourBudget: Double {
        Double(yourBudgetText.filter { "0123456789.".contains($0) }) ?? 0
    }

    func detectCurrencyIfNeeded() async {
        if selectedCurrency.code != "USD" || detectedCurrency.code != "USD" {
            return
        }
        let currency = await currencyService.detectCurrency()
        detectedCurrency = currency
        selectedCurrency = currency
    }

    func continueFromStepOne() {
        if registryType == .event {
            navigationPath.append(.eventPlanner)
        } else {
            navigationPath.append(.giftingCollaborators)
        }
    }

    func continueFromCollaborators() {
        navigationPath.append(.giftingPlanner)
    }

    func advancePlanner() {
        guard canAdvancePlanner else { return }
        if currentQuestionIndex < plannerAnswers.count - 1 {
            currentQuestionIndex += 1
        } else {
            navigationPath.append(registryType == .event ? .eventBudget : .giftingSplit)
        }
    }

    func goBackPlanner() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        } else {
            navigationPath.removeLast()
        }
    }

    func submit() async {
        isSubmitting = true
        errorMessage = nil

        var adminId = userManager.currentUser?.id.uuidString
        if adminId == nil, let session = try? await supabase.auth.session {
            adminId = session.user.id.uuidString
        }
        guard let adminId else {
            errorMessage = "Please log in to continue."
            isSubmitting = false
            return
        }

        let sanitizedPlannerAnswers = plannerAnswers.filter {
            $0.question != Self.primaryPurposeQuestion
        }

        let eventDetails = RegistryEventDetails(
            aiPlannerAnswers: registryType == .event ? sanitizedPlannerAnswers : [],
            targetBudget: registryType == .event ? parsedBudget : 0,
            paymentSplitType: .split
        )

        let giftingDetails = RegistryGiftingDetails(
            collaboratorCount: registryType == .gifting ? collaboratorCount : 1,
            aiPlannerAnswers: registryType == .gifting ? sanitizedPlannerAnswers : [],
            splitType: registryType == .gifting ? selectedSplitType : .split,
            creatorBudget: registryType == .gifting ? (selectedSplitType == .split ? parsedBudget : parsedYourBudget) : 0,
            pooledBudget: registryType == .gifting ? (selectedSplitType == .dutch ? parsedYourBudget : 0) : 0,
            budgetStatus: registryType == .gifting && selectedSplitType == .dutch ? .pending : .finalized
        )

        let initialBudget = registryType == .event ? parsedBudget : (selectedSplitType == .split ? parsedBudget : parsedYourBudget)
        let budgetSnapshot = RegistryBudgetSnapshot(
            totalBudget: initialBudget,
            spentAmount: 0,
            remainingAmount: initialBudget,
            lastUpdated: Date()
        )

        let request = CreateRegistryRequest(
            adminId: adminId,
            name: registryName,
            joinCode: generateJoinCode(),
            registryType: registryType,
            creatorName: creatorName,
            eventType: eventType,
            eventDate: eventDate,
            currency: selectedCurrency,
            eventDetails: eventDetails,
            giftingDetails: giftingDetails,
            budgetSnapshot: budgetSnapshot,
            shippingAddress: ""
        )

        do {
            let registry = try await registryService.createRegistry(request)
            createdRegistry = registry
            shouldDismiss = true
            Task {
                _ = try? await self.registryService.refreshSuggestions(registryId: registry.id, forceRefresh: false)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    func togglePlannerOption(_ option: String) {
        var selections = plannerAnswers[currentQuestionIndex].answers

        if plannerAnswers[currentQuestionIndex].allowsMultiple {
            if selections.contains(option) {
                selections.remove(option)
            } else {
                selections.insert(option)
            }
        } else {
            selections = [option]
        }

        plannerAnswers[currentQuestionIndex].answers = selections

        if selections.contains(where: isOtherOption) {
            return
        }

        plannerAnswers[currentQuestionIndex].answer = selections.sorted().joined(separator: ", ")
    }

    func isOptionSelected(_ option: String) -> Bool {
        plannerAnswers[currentQuestionIndex].answers.contains(option)
    }

    private var isOtherSelected: Bool {
        plannerAnswers[currentQuestionIndex].answers.contains(where: isOtherOption)
    }

    private func isOtherOption(_ option: String) -> Bool {
        let normalized = option.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "other" || normalized == "others"
    }

    private static let primaryPurposeQuestion = "What is the primary purpose of this event?"

    private func generateJoinCode(length: Int = 6) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in alphabet.randomElement() })
    }
}
