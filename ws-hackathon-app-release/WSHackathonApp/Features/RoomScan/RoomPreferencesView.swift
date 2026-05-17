//
//  RoomPreferencesView.swift
//  WSHackathonApp
//
//  Animated card-based preference questions (4 steps).
//

import SwiftUI

struct RoomPreferencesView: View {
    @Bindable var viewModel: RoomScanViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Progress Indicator
            progressBar
                .padding(.top, 8)
                .padding(.horizontal, 16)

            Spacer().frame(height: 16)

            // Question Card
            VStack(spacing: 8) {
                Text("Q\(viewModel.currentQuestionIndex + 1) of 4")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(Color.secondary)

                Text(viewModel.currentQuestionTitle)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .id("question_\(viewModel.currentQuestionIndex)")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 24)

            // Answer Options
            VStack(spacing: 8) {
                ForEach(viewModel.currentQuestionOptions, id: \.self) { option in
                    optionButton(option)
                }
            }
            .padding(.horizontal, 16)
            .id("options_\(viewModel.currentQuestionIndex)")
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Spacer()

            // Navigation Buttons
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        viewModel.previousQuestion()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.black, lineWidth: 1)
                    )
                }

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        viewModel.nextQuestion()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(viewModel.currentQuestionIndex == 3 ? "Analyse" : "Next")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: viewModel.currentQuestionIndex == 3 ? "sparkles" : "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.currentAnswer.isEmpty ? Color(uiColor: .tertiaryLabel) : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .disabled(viewModel.currentAnswer.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.currentQuestionIndex)
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black)
                    .frame(
                        width: geo.size.width * CGFloat(viewModel.currentQuestionIndex + 1) / 4.0,
                        height: 6
                    )
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentQuestionIndex)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Option Button
    private func optionButton(_ option: String) -> some View {
        let isSelected = viewModel.currentAnswer == option

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectAnswer(option)
            }
        }) {
            HStack {
                Text(option)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(isSelected ? Color.black : Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        isSelected ? Color.clear : Color(uiColor: .separator),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(WSPressButtonStyle())
    }
}
