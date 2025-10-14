//
//  CustomTextField.swift
//  trAInApp
//
//  Reusable text field component
//

import SwiftUI

struct CustomTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    @State private var isSecureVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(.trainBody)
                .foregroundColor(.trainTextPrimary)

            HStack {
                if isSecure && !isSecureVisible {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                        .autocapitalization(.none)
                        .focused($isFocused)
                }

                if isSecure {
                    Button(action: { isSecureVisible.toggle() }) {
                        Image(systemName: isSecureVisible ? "eye" : "eye.slash")
                            .foregroundColor(.trainTextSecondary)
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.white)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isFocused ? Color.trainPrimary : Color.trainBorder, lineWidth: isFocused ? 2 : 1)
            )
        }
    }
}
