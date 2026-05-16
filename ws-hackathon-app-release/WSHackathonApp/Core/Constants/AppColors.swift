//
//  AppColors.swift
//  WSHackathonApp
//
//  Williams Sonoma Theme Colors
//

import SwiftUI

enum AppColors {
    // MARK: - Backgrounds
    static let background       = Color(hex: "#FFFFFF")       // Pure White
    static let surfaceLight     = Color(hex: "#F7F5F2")       // Warm Cream / Off-White
    static let surfaceMedium    = Color(hex: "#EDE9E3")       // Warm Linen
    static let surfaceDark      = Color(hex: "#F2EDE6")       // Parchment

    // MARK: - Text
    static let primaryText      = Color(hex: "#1A1A1A")       // Near Black
    static let secondaryText    = Color(hex: "#6B6560")       // Warm Gray
    static let mutedText        = Color(hex: "#A09890")       // Light Warm Gray

    // MARK: - Accent
    static let accent           = Color(hex: "#1A1A1A")       // Premium Black
    static let accentLight      = Color(hex: "#333333")       // Charcoal

    // MARK: - Borders
    static let border           = Color(hex: "#D9D4CC")       // Warm Divider
    static let borderStrong     = Color(hex: "#B8B0A5")       // Stronger Divider

    // MARK: - Absolutes
    static let pureWhite        = Color(hex: "#FFFFFF")
    static let alwaysBlack      = Color(hex: "#1A1A1A")
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
