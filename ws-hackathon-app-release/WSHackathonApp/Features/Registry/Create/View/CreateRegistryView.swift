
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
        FormScaffold(title: viewModel.registryType == .event ? "Create Event Registry" : "Create Gifting Registry", showsBackButton: true, backAction: { dismiss() }) {
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
                        .foregroundStyle(Color.primary)
                    Stepper(value: $viewModel.collaboratorCount, in: 1...20) {
                        Text("\(viewModel.collaboratorCount) collaborator\(viewModel.collaboratorCount == 1 ? "" : "s")")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }

                primaryButton(title: "Next", isEnabled: true, isLoading: false) {
                    viewModel.continueFromCollaborators()
                }
            }
        }
    }

    private var plannerStep: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {

                HStack {
                    Button {
                        viewModel.goBackPlanner()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    }

                    Spacer()

                    Text("Preferences")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary)

                    Spacer()

                    Color.clear
                        .frame(width: 36, height: 36)
                }

                progressBar

                Text("Q\(viewModel.currentQuestionIndex + 1) of \(viewModel.plannerAnswers.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(viewModel.currentQuestion.question)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                ScrollView {
                    VStack(spacing: 12) {
                        if let options = viewModel.currentQuestion.options {
                            ForEach(options, id: \.self) { option in
                                optionRow(title: option, isSelected: viewModel.isOptionSelected(option))
                                    .onTapGesture {
                                        viewModel.togglePlannerOption(option)
                                    }
                            }
                        }

                        if viewModel.shouldShowCustomAnswer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Custom Answer")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.secondary)
                                    .padding(.leading, 6)

                                TextField("Enter your custom answer here", text: $viewModel.plannerAnswers[viewModel.currentQuestionIndex].answer)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(isCustomAnswer ? Color.black : Color(uiColor: .separator), lineWidth: 1)
                                    )
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            VStack {
                Spacer()
                HStack(spacing: 14) {
                    Button {
                        viewModel.goBackPlanner()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color(uiColor: .separator), lineWidth: 1)
                        )
                    }

                    Button {
                        viewModel.advancePlanner()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.canAdvancePlanner ? Color.black : Color(uiColor: .systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .disabled(!viewModel.canAdvancePlanner)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .background(
                    LinearGradient(colors: [Color(uiColor: .systemBackground).opacity(0), Color(uiColor: .systemBackground)], startPoint: .top, endPoint: .bottom)
                        .padding(.top, -20)
                )
            }
        }
        .navigationBarHidden(true)
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            let progress = CGFloat(viewModel.currentQuestionIndex + 1) / CGFloat(max(viewModel.plannerAnswers.count, 1))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(uiColor: .separator))
                    .frame(height: 6)
                Capsule()
                    .fill(Color.black)
                    .frame(width: proxy.size.width * progress, height: 6)
            }
        }
        .frame(height: 6)
    }

    private func optionRow(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.black : Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(isSelected ? Color.black : Color(uiColor: .separator), lineWidth: 1)
        )
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
                .foregroundStyle(Color.primary)
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
                .foregroundStyle(Color.primary)
            HStack {
                Text(symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.primary)
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
            .foregroundStyle(viewModel.selectedSplitType == value ? Color.white : Color.primary)
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
            .background(viewModel.selectedSplitType == value ? Color.black : Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(viewModel.selectedSplitType == value ? Color.black : Color(uiColor: .separator), lineWidth: 1)
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
                .foregroundStyle(Color.primary)
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
            .background(isEnabled ? Color.black : Color(uiColor: .systemGray4))
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
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 25))
        }
        .buttonStyle(.plain)
    }

    private var isCustomAnswer: Bool {
        let currentAnswer = viewModel.plannerAnswers[viewModel.currentQuestionIndex].answer
        return viewModel.shouldShowCustomAnswer && !currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct FormScaffold<Content: View>: View {
    let title: String
    let showsBackButton: Bool
    let backAction: (() -> Void)?
    let content: Content

    init(title: String, showsBackButton: Bool = false, backAction: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.showsBackButton = showsBackButton
        self.backAction = backAction
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if showsBackButton, let backAction {
                    Button(action: backAction) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    }
                    .buttonStyle(.plain)
                }

                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.primary)
                content
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
