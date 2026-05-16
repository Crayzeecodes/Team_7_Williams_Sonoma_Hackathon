//
//  CreateRegistryView.swift
//  WSHackathonApp
//

import SwiftUI

struct CreateRegistryView: View {
    @StateObject private var viewModel: CreateRegistryViewModel
    @Environment(\.dismiss) private var dismiss

    init(registryType: RegistryType) {
        _viewModel = StateObject(wrappedValue: CreateRegistryViewModel(registryType: registryType))
    }

    @State private var showDiscardAlert = false

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            commonStepOne
                .navigationDestination(for: CreateRegistryViewModel.CreationStep.self) { step in
                    switch step {
                    case .giftingCollaborators:
                        collaboratorStep
                    case .eventPlanner, .giftingPlanner:
                        plannerStep
                    case .eventBudget:
                        eventBudgetStep
                    case .giftingSplit:
                        giftingSplitStep
                    }
                }
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            handleDismiss()
                        } label: {
                            Image(systemName: viewModel.navigationPath.isEmpty ? "xmark" : "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(AppColors.primaryText)
                        }
                    }
                }
                .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                    Button("Keep Editing", role: .cancel) { }
                    Button("Discard", role: .destructive) { dismiss() }
                } message: {
                    Text("Are you sure you want to stop? Your progress will not be saved.")
                }
                .task {
                    await viewModel.detectCurrencyIfNeeded()
                }
                .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                    if shouldDismiss { dismiss() }
                }
        }
    }

    private func handleDismiss() {
        if viewModel.navigationPath.isEmpty {
            if viewModel.hasChanges {
                showDiscardAlert = true
            } else {
                dismiss()
            }
        } else {
            viewModel.goBack()
        }
    }

    private var commonStepOne: some View {
        FormScaffold(title: viewModel.registryType == .event ? "Create Event Registry" : "Create Gifting Registry") {
            VStack(spacing: 18) {
                formField(title: "Creator Name") {
                    TextField("Enter your name", text: $viewModel.creatorName)
                        .textInputAutocapitalization(.words)
                }

                formField(title: "Event Name") {
                    TextField("e.g. Sarah's 30th", text: $viewModel.registryName)
                        .textInputAutocapitalization(.words)
                }

                formField(title: "Event Type") {
                    Picker("Event Type", selection: $viewModel.eventType) {
                        ForEach(RegistryEventType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                formField(title: "Event Date") {
                    DatePicker(
                        "Event Date",
                        selection: $viewModel.eventDate,
                        in: Calendar.current.startOfDay(for: Date())...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
                
                Spacer()
            }
            .padding(.bottom, 100)
            .overlay(alignment: .bottom) {
                primaryButton(title: "Next", isEnabled: viewModel.canContinueFromStepOne, isLoading: false) {
                    viewModel.continueFromStepOne()
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var collaboratorStep: some View {
        FormScaffold(title: "Collaborators") {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("How many collaborators are joining?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                    Stepper(value: $viewModel.collaboratorCount, in: 1...20) {
                        Text("\(viewModel.collaboratorCount) collaborator\(viewModel.collaboratorCount == 1 ? "" : "s")")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .padding()
                    .background(AppColors.pureWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }

                Spacer()
            }
            .padding(.bottom, 100)
            .overlay(alignment: .bottom) {
                primaryButton(title: "Next", isEnabled: true, isLoading: false) {
                    viewModel.continueFromCollaborators()
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var plannerStep: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Step \(viewModel.currentQuestionIndex + 1)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                
                Text(viewModel.currentQuestion.question)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Please select an option below or enter your own answer to help our AI give better suggestions.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
                
                ScrollView {
                    VStack(spacing: 12) {
                        if let options = viewModel.currentQuestion.options {
                            ForEach(options, id: \.self) { option in
                                Button {
                                    if option == "Other" {
                                        viewModel.plannerAnswers[viewModel.currentQuestionIndex].answer = ""
                                    } else {
                                        if viewModel.plannerAnswers[viewModel.currentQuestionIndex].allowsMultiple {
                                            if viewModel.plannerAnswers[viewModel.currentQuestionIndex].answers.contains(option) {
                                                viewModel.plannerAnswers[viewModel.currentQuestionIndex].answers.remove(option)
                                            } else {
                                                viewModel.plannerAnswers[viewModel.currentQuestionIndex].answers.insert(option)
                                            }
                                        } else {
                                            viewModel.plannerAnswers[viewModel.currentQuestionIndex].answer = option
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(option)
                                            .font(.system(size: 17, weight: .semibold))
                                        Spacer()
                                        if (viewModel.plannerAnswers[viewModel.currentQuestionIndex].allowsMultiple && viewModel.plannerAnswers[viewModel.currentQuestionIndex].answers.contains(option)) ||
                                           (!viewModel.plannerAnswers[viewModel.currentQuestionIndex].allowsMultiple && viewModel.plannerAnswers[viewModel.currentQuestionIndex].answer == option) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(AppColors.alwaysBlack)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke((viewModel.plannerAnswers[viewModel.currentQuestionIndex].allowsMultiple && viewModel.plannerAnswers[viewModel.currentQuestionIndex].answers.contains(option)) ||
                                                    (!viewModel.plannerAnswers[viewModel.currentQuestionIndex].allowsMultiple && viewModel.plannerAnswers[viewModel.currentQuestionIndex].answer == option) ? AppColors.alwaysBlack : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom Answer")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.secondaryText)
                                .padding(.leading, 4)
                            
                            TextField("Enter your custom answer here", text: $viewModel.plannerAnswers[viewModel.currentQuestionIndex].answer)
                                .padding()
                                .background(Color(uiColor: .secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(isCustomAnswer ? AppColors.alwaysBlack : Color.clear, lineWidth: 2)
                                )
                        }
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 120)
                }
            }
            .padding(24)
            
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    if viewModel.currentQuestionIndex > 0 || !viewModel.navigationPath.isEmpty {
                        secondaryButton(title: "Previous") {
                            viewModel.goBackPlanner()
                        }
                    }
                    
                    primaryButton(title: "Next", isEnabled: viewModel.canAdvancePlanner, isLoading: false) {
                        viewModel.advancePlanner()
                    }
                }
                .padding(24)
                .background(
                    LinearGradient(colors: [Color(uiColor: .systemBackground).opacity(0), Color(uiColor: .systemBackground)], startPoint: .top, endPoint: .bottom)
                        .padding(.top, -20)
                )
            }
        }
    }

    private var isCustomAnswer: Bool {
        guard let options = viewModel.currentQuestion.options else { return true }
        let currentAnswer = viewModel.plannerAnswers[viewModel.currentQuestionIndex].answer
        return !currentAnswer.isEmpty && !options.contains(currentAnswer)
    }

    private var eventBudgetStep: some View {
        FormScaffold(title: "Budget") {
            VStack(spacing: 18) {
                currencyPicker
                budgetField(title: "Budget amount", text: $viewModel.budgetText, symbol: viewModel.selectedCurrency.symbol)
                Spacer()
            }
            .padding(.bottom, 100)
            .overlay(alignment: .bottom) {
                submitArea(enabled: viewModel.canSubmitEventBudget)
                    .padding(.bottom, 20)
            }
        }
    }

    private var giftingSplitStep: some View {
        FormScaffold(title: "Split Type") {
            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    splitCard(title: "Split equally", value: .split)
                    splitCard(title: "Dutch (individual budgets)", value: .dutch)
                }

                currencyPicker

                if viewModel.selectedSplitType == .split {
                    budgetField(title: "Budget amount", text: $viewModel.budgetText, symbol: viewModel.selectedCurrency.symbol)
                } else {
                    budgetField(title: "Your individual budget", text: $viewModel.yourBudgetText, symbol: viewModel.selectedCurrency.symbol)
                }
                
                Spacer()
            }
            .padding(.bottom, 100)
            .overlay(alignment: .bottom) {
                submitArea(enabled: viewModel.canSubmitGiftingBudget)
                    .padding(.bottom, 20)
            }
        }
    }

    private var currencyPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Currency")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
            Picker("Currency", selection: $viewModel.selectedCurrency) {
                ForEach(viewModel.currencyOptions, id: \.self) { currency in
                    Text("\(currency.code) (\(currency.symbol))")
                        .tag(currency)
                }
            }
            .pickerStyle(.menu)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }

    private func budgetField(title: String, text: Binding<String>, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
            HStack {
                Text(symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 22, weight: .bold))
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }

    private func splitCard(title: String, value: RegistryPaymentSplitType) -> some View {
        Button {
            viewModel.selectedSplitType = value
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: value == .split ? "person.2.fill" : "creditcard.fill")
                    .font(.system(size: 24, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(viewModel.selectedSplitType == value ? .white : AppColors.primaryText)
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
            .background(viewModel.selectedSplitType == value ? AppColors.alwaysBlack : Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(viewModel.selectedSplitType == value ? AppColors.alwaysBlack : AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func submitArea(enabled: Bool) -> some View {
        VStack(spacing: 12) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            primaryButton(title: "Done", isEnabled: enabled, isLoading: viewModel.isSubmitting) {
                Task { await viewModel.submit() }
            }
        }
    }

    private func formField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
            content()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }

    private func primaryButton(title: String, isEnabled: Bool, isLoading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
                Spacer()
            }
            .padding(.vertical, 16)
            .background(isEnabled ? AppColors.alwaysBlack : AppColors.borderStrong)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }

    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct FormScaffold<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                content
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
