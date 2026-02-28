//
//  PasswordResetRequestView.swift
//  TrainSwift
//
//  Password reset - enter email screen
//

import SwiftUI

struct PasswordResetRequestView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var navigateToCode: Bool = false
    @State private var resetCode: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                    Spacer()
                        .frame(height: 60)

                    // Logo
                    Text("train.")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.trainPrimary)

                    Spacer()
                        .frame(height: ElementHeight.tabSelector)

                    // Title
                    Text("Reset Password")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    // Email input
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding(Spacing.md)
                            .appCard()
                            .cornerRadius(CornerRadius.sm)

                        Text("Enter your email and we'll send you a reset code")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, Spacing.lg)

                    if showError {
                        Text(errorMessage)
                            .font(.trainCaption)
                            .foregroundColor(.trainError)
                            .padding(.horizontal, Spacing.lg)
                    }

                    Spacer()

                    // Bottom section
                    VStack(spacing: Spacing.md) {
                        HStack(spacing: Spacing.xs) {
                            Text("Remember your password?")
                                .font(.trainBody)
                                .foregroundColor(.trainTextSecondary)

                            Button(action: { dismiss() }) {
                                Text("Log In")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.trainPrimary)
                            }
                        }

                        Button(action: handleContinue) {
                            Text("Continue")
                                .font(.trainBodyMedium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: ButtonHeight.standard)
                                .background(Color.trainPrimary)
                                .cornerRadius(CornerRadius.pill)
                        }
                        .disabled(email.isEmpty)
                        .opacity(email.isEmpty ? 0.6 : 1.0)
                        .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.bottom, 40)
                }

                if navigateToCode {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            navigateToCode = false
                        }

                    PasswordResetCodeView(
                        email: email,
                        expectedCode: resetCode,
                        onSuccess: { dismiss() },
                        onDismiss: { navigateToCode = false }
                    )
                    .transition(.move(edge: .bottom))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.trainTextPrimary)
                    }
                }
            }
    }

    private func handleContinue() {
        showError = false

        // Validate email with proper regex
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            errorMessage = String(localized: "Please enter a valid email address")
            showError = true
            return
        }

        // Generate 6-digit code (in real app, this would be sent via email)
        resetCode = String(format: "%06d", Int.random(in: 0...999999))
        AppLogger.logAuth("[PASSWORD RESET] Reset code sent to: \(email)")

        // Show code entry modal
        withAnimation {
            navigateToCode = true
        }
    }
}

#Preview {
    PasswordResetRequestView()
}
