//
//  WSThemePrimitives.swift
//  WSHackathonApp
//

import SwiftUI

enum WSThemePrimitives {
    static let cornerRadius: CGFloat = 25
    static let cardShadowColor = Color.black.opacity(0.12)
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowX: CGFloat = 0
    static let cardShadowY: CGFloat = 6
}

extension View {
    func wsCardStyle(
        background: Color = Color(uiColor: .systemBackground),
        cornerRadius: CGFloat = WSThemePrimitives.cornerRadius
    ) -> some View {
        self
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: WSThemePrimitives.cardShadowColor,
                radius: WSThemePrimitives.cardShadowRadius,
                x: WSThemePrimitives.cardShadowX,
                y: WSThemePrimitives.cardShadowY
            )
    }

    func wsButtonShape(cornerRadius: CGFloat = WSThemePrimitives.cornerRadius) -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
