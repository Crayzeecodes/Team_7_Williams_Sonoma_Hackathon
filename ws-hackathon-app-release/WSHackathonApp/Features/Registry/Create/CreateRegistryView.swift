// CreateRegistryView.swift
// WSHackathonApp — Multi-step registry creation (.fullScreenCover)

import SwiftUI

struct CreateRegistryView: View {
    let registryType: RegistryType
    let onCreated: (RegistryModel) -> Void

    @StateObject private var viewModel = CreateRegistryViewModel()
    @Environment(\.dismiss) private var dismiss

    // Internal NavigationStack step
    enum CreateStep { case step1, questions, budget, collaboratorCount, splitType }
    @State private var step: CreateStep = .step1

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F1923").ignoresSafeArea()
                Group {
                    switch step {
                    case .step1:          step1View
                    case .questions:      questionsView
                    case .budget:         budgetView
                    case .collaboratorCount: collaboratorCountView
                    case .splitType:      splitTypeView
                    }
                }
                .transition(.asymmetric(
                    insertion: .push(from: .trailing),
                    removal: .push(from: .leading)
                ))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "F2A623"))
                }
            }
        }
        .onChange(of: viewModel.createdRegistry) { _, registry in
            if let r = registry {
                viewModel.triggerAISuggestions(for: r.id)
                onCreated(r)
                dismiss()
            }
        }
    }

    // MARK: - Step 1: Common fields

    private var step1View: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                stepHeader(
                    icon: registryType == .event ? "calendar.badge.plus" : "gift.fill",
                    title: registryType == .event ? "Create an Event Registry" : "Create a Gifting Registry",
                    subtitle: "Let's start with the basics"
                )

                formField(label: "Your Name") {
                    StyledTextField(placeholder: "e.g. Jane Smith", text: $viewModel.creatorName)
                }

                formField(label: "Registry Name") {
                    StyledTextField(placeholder: "e.g. Sarah's 30th Birthday", text: $viewModel.eventName)
                }

                formField(label: "Event Type") {
                    Menu {
                        ForEach(EventType.allCases) { et in
                            Button(et.displayName) { viewModel.selectedEventType = et }
                        }
                    } label: {
                        HStack {
                            Image(systemName: viewModel.selectedEventType.sfSymbol)
                                .foregroundStyle(Color(hex: "F2A623"))
                            Text(viewModel.selectedEventType.displayName)
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption).foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(14)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                formField(label: "Event Date") {
                    DatePicker("", selection: $viewModel.eventDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .padding(14)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        .tint(Color(hex: "F2A623"))
                }

                nextButton(disabled: !viewModel.isStep1Valid) {
                    withAnimation {
                        step = registryType == .event ? .questions : .collaboratorCount
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Collaborator Count (gifting only)

    private var collaboratorCountView: some View {
        VStack(spacing: 32) {
            stepHeader(
                icon: "person.3.fill",
                title: "How many collaborators?",
                subtitle: "Including yourself"
            )

            VStack(spacing: 16) {
                Text("\(viewModel.collaboratorCount)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(Color(hex: "F2A623"))

                HStack(spacing: 40) {
                    Button {
                        if viewModel.collaboratorCount > 1 { viewModel.collaboratorCount -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(viewModel.collaboratorCount > 1 ? Color(hex: "F2A623") : .gray)
                    }
                    Button {
                        if viewModel.collaboratorCount < 20 { viewModel.collaboratorCount += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(hex: "F2A623"))
                    }
                }

                Text("1 – 20 collaborators")
                    .font(.caption).foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            nextButton(disabled: false) {
                withAnimation { step = .questions }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - AI Planner Questions (card-style page)

    private var questionsView: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<viewModel.plannerQuestions.count, id: \.self) { i in
                    Circle()
                        .fill(i <= viewModel.currentQuestionIndex ? Color(hex: "F2A623") : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                        .animation(.spring(), value: viewModel.currentQuestionIndex)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 28)

            // Question card
            VStack(alignment: .leading, spacing: 20) {
                Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.plannerQuestions.count)")
                    .font(.caption).foregroundStyle(Color(hex: "F2A623")).textCase(.uppercase)

                Text(viewModel.currentQuestion)
                    .font(.title3).fontWeight(.bold).foregroundStyle(.white)
                    .lineLimit(4).fixedSize(horizontal: false, vertical: true)

                TextField("Your answer…", text: viewModel.currentAnswer, axis: .vertical)
                    .lineLimit(3...6)
                    .foregroundStyle(.white)
                    .tint(Color(hex: "F2A623"))
                    .padding(14)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(hex: "F2A623").opacity(0.3))
                    )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1B2B4B").opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
            )
            .padding(.horizontal, 20)

            Spacer()

            // Navigation buttons
            HStack(spacing: 16) {
                if viewModel.currentQuestionIndex > 0 {
                    Button {
                        viewModel.goToPreviousQuestion()
                    } label: {
                        Text("Back")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(16)
                            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    }
                }

                Button {
                    if viewModel.isLastQuestion {
                        withAnimation { step = .budget }
                    } else {
                        viewModel.goToNextQuestion()
                    }
                } label: {
                    Text(viewModel.isLastQuestion ? "Done →" : "Next →")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "0F1923"))
                        .frame(maxWidth: .infinity).padding(16)
                        .background(Color(hex: "F2A623"), in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(viewModel.plannerAnswers[viewModel.currentQuestionIndex].trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Split Type (gifting only)

    private var splitTypeView: some View {
        VStack(spacing: 28) {
            stepHeader(
                icon: "dollarsign.circle.fill",
                title: "How will costs be split?",
                subtitle: "Choose your payment style"
            )

            VStack(spacing: 16) {
                splitOptionCard(
                    icon: "divide.circle.fill",
                    title: "Split Equally",
                    description: "Set a total budget and split it among all contributors automatically.",
                    isSelected: viewModel.splitType == .split
                ) { viewModel.splitType = .split }

                splitOptionCard(
                    icon: "person.fill.checkmark",
                    title: "Dutch (Individual Budgets)",
                    description: "Each collaborator sets and contributes their own individual budget.",
                    isSelected: viewModel.splitType == .dutch
                ) { viewModel.splitType = .dutch }
            }

            Spacer()

            nextButton(disabled: false) {
                withAnimation { step = .budget }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Budget Screen

    private var budgetView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                stepHeader(
                    icon: "banknote.fill",
                    title: registryType == .event ? "Set Your Budget" : (viewModel.splitType == .dutch ? "Your Individual Budget" : "Total Budget"),
                    subtitle: "We'll auto-detect your local currency"
                )

                // Currency row
                VStack(alignment: .leading, spacing: 8) {
                    Text("Currency").font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.6)).textCase(.uppercase)
                    HStack {
                        Text(viewModel.currency.symbol)
                            .font(.title2).foregroundStyle(Color(hex: "F2A623"))
                        Text(viewModel.currency.code)
                            .font(.title3).foregroundStyle(.white)
                        Spacer()
                        if viewModel.isDetectingCurrency {
                            ProgressView().tint(Color(hex: "F2A623"))
                        } else {
                            Button("Detect") {
                                Task { await viewModel.detectCurrency() }
                            }
                            .font(.caption).foregroundStyle(Color(hex: "F2A623"))
                        }
                    }
                    .padding(14)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }

                // Budget amount
                formField(label: registryType == .gifting && viewModel.splitType == .dutch ? "Your Budget (\(viewModel.currency.code))" : "Total Budget (\(viewModel.currency.code))") {
                    HStack {
                        Text(viewModel.currency.symbol)
                            .foregroundStyle(Color(hex: "F2A623")).font(.title3)
                        TextField("0.00",
                                  text: registryType == .gifting && viewModel.splitType == .dutch ? $viewModel.individualBudgetText : $viewModel.budgetText)
                            .keyboardType(.decimalPad)
                            .foregroundStyle(.white).font(.title3)
                    }
                    .padding(14)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "F2A623").opacity(0.3)))
                }

                if let err = viewModel.error {
                    Text(err).font(.subheadline).foregroundStyle(.red.opacity(0.85))
                        .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                }

                // Create button
                Button {
                    Task {
                        if registryType == .event {
                            await viewModel.submitEventRegistry()
                        } else {
                            await viewModel.submitGiftingRegistry()
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isSubmitting {
                            ProgressView().tint(Color(hex: "0F1923"))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Create Registry")
                        }
                    }
                    .font(.headline).fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "0F1923"))
                    .frame(maxWidth: .infinity).padding(16)
                    .background(Color(hex: "F2A623"), in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(viewModel.isSubmitting)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .task { await viewModel.detectCurrency() }
    }

    // MARK: - Helpers

    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "F2A623"))
                .padding(.top, 20)
            Text(title)
                .font(.title2).fontWeight(.bold).foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline).foregroundStyle(.white.opacity(0.55))
        }
    }

    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.caption).fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.6)).textCase(.uppercase)
            content()
        }
    }

    private func nextButton(disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Continue →")
                .font(.headline).fontWeight(.semibold)
                .foregroundStyle(disabled ? .white.opacity(0.4) : Color(hex: "0F1923"))
                .frame(maxWidth: .infinity).padding(16)
                .background(
                    disabled ? Color.white.opacity(0.08) : Color(hex: "F2A623"),
                    in: RoundedRectangle(cornerRadius: 14)
                )
        }
        .disabled(disabled)
    }

    private func splitOptionCard(icon: String, title: String, description: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color(hex: "F2A623") : .white.opacity(0.5))
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                    Text(description)
                        .font(.caption).foregroundStyle(.white.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "F2A623"))
                }
            }
            .padding(16)
            .background(
                isSelected ? Color(hex: "F2A623").opacity(0.12) : Color.white.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color(hex: "F2A623").opacity(0.6) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Styled TextField helper

private struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .foregroundStyle(.white)
            .tint(Color(hex: "F2A623"))
            .padding(14)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(text.isEmpty ? Color.clear : Color(hex: "F2A623").opacity(0.4))
            )
    }
}
