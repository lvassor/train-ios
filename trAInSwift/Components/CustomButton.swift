//
//  CustomButton.swift
//  trAInApp
//
//  Reusable button component
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var style: ButtonStyle = .primary

    enum ButtonStyle {
        case primary
        case secondary
        case text
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.trainBodyMedium)  // 18px Medium from Figma
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: ElementHeight.button)  // 50px from Figma
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                .shadow(color: style == .primary && isEnabled ? Color.trainPrimary.opacity(0.4) : .clear, radius: 16, x: 0, y: 8)
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }

    private var backgroundColor: Color {
        if !isEnabled {
            return .trainDisabled
        }
        switch style {
        case .primary:
            return .trainPrimary
        case .secondary:
            return .clear
        case .text:
            return .clear
        }
    }

    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .text:
            return .trainPrimary
        }
    }
}
