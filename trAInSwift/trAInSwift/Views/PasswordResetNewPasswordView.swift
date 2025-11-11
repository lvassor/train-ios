//
//  PasswordResetNewPasswordView.swift
//  trAInSwift
//
//  Password reset - create new password
//

import SwiftUI

struct PasswordResetNewPasswordView: View {
    @Environment(\.dismiss) var dismiss
    let onSuccess: () -> Void

    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false

    var body: some View {
        ZStack {
            Color.trainBackground.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()
                    .frame(height: 60)

                // Logo
                Text("train.")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.trainPrimary)

                Spacer()
                    .frame(height: 40)

                // Title
                Text("Create New Password")
                    .font(.trainTitle)
                    .foregroundColor(.trainTextPrimary)

                // Password inputs
                VStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("New password")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)

                        HStack {
                            if showNewPassword {
                                TextField("Enter new password", text: $newPassword)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("Enter new password", text: $newPassword)
                            }

                            Button(action: { showNewPassword.toggle() }) {
                                Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.trainTextSecondary)
                            }
                        }
                        .padding(Spacing.md)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.trainBorder, lineWidth: 1)
                        )
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Confirm new password")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)

                        HStack {
                            if showConfirmPassword {
                                TextField("Confirm new password", text: $confirmPassword)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("Confirm new password", text: $confirmPassword)
                            }

                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.trainTextSecondary)
                            }
                        }
                        .padding(Spacing.md)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.trainBorder, lineWidth: 1)
                        )
                    }

                    if showError {
                        Text(errorMessage)
                            .font(.trainCaption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()

                Button(action: handleContinue) {
                    Text("Continue")
                        .font(.trainBodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.standard)
                        .background(Color.trainPrimary)
                        .cornerRadius(30)
                }
                .disabled(newPassword.isEmpty || confirmPassword.isEmpty)
                .opacity(newPassword.isEmpty || confirmPassword.isEmpty ? 0.6 : 1.0)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 40)
            }

            if showSuccess {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Password Updated Successfully")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.xl)
                .background(Color.trainBackground)
                .cornerRadius(20)
                .shadow(radius: 20)
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    private func handleContinue() {
        showError = false

        // Validate password length
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            showError = true
            return
        }

        // Validate passwords match
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }

        // In real app, would update password in database
        print("✅ Password updated successfully")

        // Show success message
        showSuccess = true

        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
            onSuccess()
        }
    }
}

#Preview {
    PasswordResetNewPasswordView(onSuccess: {})
}
