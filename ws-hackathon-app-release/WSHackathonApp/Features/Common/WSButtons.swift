//
//  WSButtons.swift
//  WSHackathonApp
//
//  Reusable button styles and section header.
//

import SwiftUI

// MARK: - Primary Button (Black fill, white text)
struct WSPrimaryButton: View {
    let title: String
    var isCompact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: isCompact ? 13 : 15, weight: .semibold))
                .tracking(isCompact ? 1 : 1.5)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: isCompact ? 40 : 50)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(WSPressButtonStyle())
    }
}

// MARK: - Secondary Button (White fill, black border)
struct WSSecondaryButton: View {
    let title: String
    var isCompact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: isCompact ? 13 : 15, weight: .semibold))
                .tracking(isCompact ? 1 : 1.5)
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: isCompact ? 40 : 50)
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 1)
                )
        }
        .buttonStyle(WSPressButtonStyle())
    }
}

// MARK: - Press Button Style
struct WSPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Section Header
struct WSSectionHeader<Destination: View>: View {
    let title: String
    var destination: Destination? = nil

    init(title: String) where Destination == EmptyView {
        self.title = title
        self.destination = nil
    }

    init(title: String, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.destination = destination()
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary)

            Spacer()

            if let destination {
                NavigationLink(destination: destination) {
                    Text("See All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.black)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 10)
    }
}

// MARK: - Star Rating View
struct StarRatingView: View {
    let rating: Double
    var maxRating: Int = 5
    var size: CGFloat = 12
    var spacing: CGFloat = 2

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starImageName(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(index <= Int(rating) ? Color.black : Color(uiColor: .separator))
            }
        }
        .accessibilityLabel("\(String(format: "%.1f", rating)) out of \(maxRating) stars")
    }

    private func starImageName(for index: Int) -> String {
        let diff = rating - Double(index - 1)
        if diff >= 1 { return "star.fill" }
        else if diff >= 0.5 { return "star.leadinghalf.filled" }
        else { return "star" }
    }
}
