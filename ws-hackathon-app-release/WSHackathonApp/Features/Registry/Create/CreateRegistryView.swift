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
                .task {
                    await viewModel.detectCurrencyIfNeeded()
                }
                .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                    if shouldDismiss { dismiss() }
                }
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

                primaryButton(title: "Next", isEnabled: viewModel.canContinueFromStepOne, isLoading: false) {
                    viewModel.continueFromStepOne()
                }
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

                primaryButton(title: "Next", isEnabled: true, isLoading: false) {
                    viewModel.continueFromCollaborators()
                }
            }
        }
    }

    private var plannerStep: some View {
        FormScaffold(title: "Planner") {
            VStack(spacing: 18) {
                TabView(selection: $viewModel.currentQuestionIndex) {
                    ForEach(Array(viewModel.plannerAnswers.enumerated()), id: \.offset) { index, answer in
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Question \(index + 1)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.secondaryText)
                            Text(answer.question)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(AppColors.primaryText)
                            TextField(
                                "Your answer",
                                text: Binding(
                                    get: { viewModel.plannerAnswers[index].answer },
                                    set: { viewModel.plannerAnswers[index].answer = $0 }
                                )
                            )
                            .keyboardType(index == 1 ? .numberPad : .default)
                            .textInputAutocapitalization(.sentences)
                            .padding()
                            .background(AppColors.pureWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 320)

                HStack(spacing: 12) {
                    secondaryButton(title: "Back") {
                        viewModel.goBackPlanner()
                    }

                    primaryButton(
                        title: viewModel.currentQuestionIndex == viewModel.plannerAnswers.count - 1 ? "Next" : "Next",
                        isEnabled: viewModel.canAdvancePlanner,
                        isLoading: false
                    ) {
                        viewModel.advancePlanner()
                    }
                }
            }
        }
    }

    private var eventBudgetStep: some View {
        FormScaffold(title: "Budget") {
            VStack(spacing: 18) {
                currencyPicker
                budgetField(title: "Budget amount", text: $viewModel.budgetText, symbol: viewModel.selectedCurrency.symbol)
                submitArea(enabled: viewModel.canSubmitEventBudget)
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

                submitArea(enabled: viewModel.canSubmitGiftingBudget)
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
            .background(AppColors.pureWhite)
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
            .background(AppColors.pureWhite)
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
            .foregroundStyle(viewModel.selectedSplitType == value ? AppColors.pureWhite : AppColors.primaryText)
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
            .background(viewModel.selectedSplitType == value ? AppColors.accent : AppColors.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(viewModel.selectedSplitType == value ? AppColors.accent : AppColors.border, lineWidth: 1)
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
                .background(AppColors.pureWhite)
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
            .clipShape(RoundedRectangle(cornerRadius: 25))
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
                .background(AppColors.surfaceMedium)
                .clipShape(RoundedRectangle(cornerRadius: 25))
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
        .background(AppColors.surfaceLight.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
