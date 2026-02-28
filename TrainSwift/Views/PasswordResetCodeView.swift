//
//  PasswordResetCodeView.swift
//  TrainSwift
//
//  Password reset - enter verification code
//

import SwiftUI
import UIKit

struct PasswordResetCodeView: View {
    let email: String
    let expectedCode: String
    let onSuccess: () -> Void
    let onDismiss: () -> Void

    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedField: Int?
    @State private var showError: Bool = false
    @State private var navigateToNewPassword: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @State private var showSuccess: Bool = false
    @State private var resendCooldown: Int = 0
    @State private var resendTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.xl) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.trainPrimary.opacity(0.1))
                        .frame(width: IconSize.display, height: IconSize.display)

                    Image(systemName: "envelope.fill")
                        .font(.system(size: IconSize.xl))
                        .foregroundColor(.trainPrimary)
                }
                .padding(.top, Spacing.xl)

                // Title and subtitle
                VStack(spacing: Spacing.sm) {
                    Text("Reset Email Sent")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text("Enter the 6 digit code")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                }

                // Warning text
                Text("Check your junk inbox if you do not receive your code")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                // Code input boxes
                HStack(spacing: Spacing.sm) {
                    ForEach(0..<6, id: \.self) { index in
                        TextField("", text: $code[index])
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 48, height: 56)
                            .appCard()
                            .cornerRadius(CornerRadius.xs)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.xs)
                                    .stroke(showError ? Color.trainError : Color.clear, lineWidth: 2)
                            )
                            .font(.trainSmallNumber).fontWeight(.bold)
                            .focused($focusedField, equals: index)
                            .onChange(of: code[index]) { oldValue, newValue in
                                handleCodeInput(index: index, oldValue: oldValue, newValue: newValue)
                            }
                    }
                }
                .offset(x: shakeOffset)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)

                if showError {
                    Text("Invalid code. Please try again.")
                        .font(.trainCaption)
                        .foregroundColor(.trainError)
                }

                // Resend code option
                if resendCooldown > 0 {
                    Text("Resend code in \(resendCooldown)s")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                } else {
                    Button(action: resendCode) {
                        Text("Resend Code")
                            .font(.trainCaption)
                            .foregroundColor(.trainPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .appCard()
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadowStyle(.modal)
            .overlay {
                if showSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.trainSuccess)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $navigateToNewPassword, onDismiss: {
            onSuccess()
        }) {
            PasswordResetNewPasswordView(onSuccess: {
                navigateToNewPassword = false
            })
        }
        .onAppear {
            // Auto-focus first field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = 0
            }
        }
    }

    private func handleCodeInput(index: Int, oldValue: String, newValue: String) {
        // Limit to single digit
        if newValue.count > 1 {
            code[index] = String(newValue.suffix(1))
        }

        // Auto-advance to next field
        if !newValue.isEmpty && index < 5 {
            focusedField = index + 1
        }

        // Auto-submit when all 6 digits entered
        if index == 5 && !newValue.isEmpty {
            verifyCode()
        }

        // Clear error when user types
        if showError {
            showError = false
        }
    }

    private func verifyCode() {
        let enteredCode = code.joined()

        if enteredCode == expectedCode {
            // Code is correct
            AppLogger.logAuth("[PASSWORD RESET] Code verified successfully")
            showError = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring()) {
                showSuccess = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onDismiss()
                navigateToNewPassword = true
            }
        } else {
            // Code is incorrect
            AppLogger.logAuth("[PASSWORD RESET] Invalid code entered", level: .error)
            showError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
                shakeOffset = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                shakeOffset = 0
            }

            // Clear all fields and refocus first
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                code = Array(repeating: "", count: 6)
                focusedField = 0
            }
        }
    }

    private func resendCode() {
        resendCooldown = 60
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                timer.invalidate()
                resendTimer = nil
            }
        }
        AppLogger.logAuth("[PASSWORD RESET] Resend code requested for email: \(email)")
    }
}

// RoundedCorner helper is already defined in QuestionnaireSteps.swift

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        PasswordResetCodeView(
            email: "test@test.com",
            expectedCode: "123456",
            onSuccess: {},
            onDismiss: {}
        )
    }
}
