//
//  RegistryPlannerEditorView.swift
//  WSHackathonApp
//

import SwiftUI

struct RegistryPlannerEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var answers: [RegistryPlannerAnswer]
    let isSaving: Bool
    let onSave: ([RegistryPlannerAnswer]) -> Void

    init(
        answers: [RegistryPlannerAnswer],
        isSaving: Bool,
        onSave: @escaping ([RegistryPlannerAnswer]) -> Void
    ) {
        _answers = State(initialValue: answers)
        self.isSaving = isSaving
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(answers.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Question \(index + 1)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.secondary)

                            Text(answers[index].question)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.primary)

                            if let options = answers[index].options {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(options, id: \.self) { option in
                                        plannerOptionButton(option, answer: $answers[index])
                                    }
                                }
                            }

                            if shouldShowCustomAnswer(for: answers[index]) {
                                TextField("Enter your custom answer here", text: $answers[index].answer)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                    }
                }
                .padding(16)
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Edit AI Answers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSave(normalizedAnswers)
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private var normalizedAnswers: [RegistryPlannerAnswer] {
        answers.map { answer in
            var copy = answer
            if !shouldShowCustomAnswer(for: answer) {
                copy.answer = answer.answers.sorted().joined(separator: ", ")
            }
            return copy
        }
    }

    private func plannerOptionButton(_ option: String, answer: Binding<RegistryPlannerAnswer>) -> some View {
        let selected = answer.wrappedValue.answers.contains(option)

        return Button {
            toggleOption(option, answer: answer)
        } label: {
            HStack {
                Text(option)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(selected ? Color.white : Color.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.black : Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func toggleOption(_ option: String, answer: Binding<RegistryPlannerAnswer>) {
        var updated = answer.wrappedValue

        if updated.allowsMultiple {
            if updated.answers.contains(option) {
                updated.answers.remove(option)
            } else {
                updated.answers.insert(option)
            }
        } else {
            updated.answers = [option]
        }

        if !shouldShowCustomAnswer(for: updated) {
            updated.answer = updated.answers.sorted().joined(separator: ", ")
        }

        answer.wrappedValue = updated
    }

    private func shouldShowCustomAnswer(for answer: RegistryPlannerAnswer) -> Bool {
        answer.answers.contains(where: isOtherOption)
    }

    private func isOtherOption(_ option: String) -> Bool {
        let normalized = option.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "other" || normalized == "others"
    }
}
