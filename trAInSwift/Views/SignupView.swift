//
//  SignupView.swift
//  trAInApp
//
//  Signup screen for creating new accounts
//

import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var onSignupSuccess: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                    VStack(spacing: Spacing.xl) {
                        Spacer()
                            .frame(height: 40)

                        // Header
                        VStack(spacing: Spacing.sm) {
                            Text("Create Account")
                                .font(.trainTitle)
                                .foregroundColor(.trainTextPrimary)

                            Text("Start your fitness journey today")
                                .font(.trainSubtitle)
                                .foregroundColor(.trainTextSecondary)
                        }

                        // Signup Form
                        VStack(spacing: Spacing.lg) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Email")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.trainTextPrimary)

                                TextField("Enter your email", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .padding(Spacing.md)
                                    .appCard()
                                    .cornerRadius(CornerRadius.md)
                            }

                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Password")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.trainTextPrimary)

                                SecureField("Enter your password", text: $password)
                                    .padding(Spacing.md)
                                    .appCard()
                                    .cornerRadius(CornerRadius.md)

                                Text("Must be at least 6 characters")
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                            }

                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Confirm Password")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.trainTextPrimary)

                                SecureField("Confirm your password", text: $confirmPassword)
                                    .padding(Spacing.md)
                                    .appCard()
                                    .cornerRadius(CornerRadius.md)
                            }

                            if showError {
                                Text(errorMessage)
                                    .font(.trainCaption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, Spacing.sm)
                            }

                            Button(action: handleSignup) {
                                Text("Create Account")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: ButtonHeight.standard)
                                    .background(Color.trainPrimary)
                                    .cornerRadius(CornerRadius.md)
                            }
                            .disabled(!isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                        }
                        .padding(.horizontal, Spacing.lg)

                        Spacer()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.trainTextPrimary)
                    }
                }
            }
            .charcoalGradientBackground()
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }

    private func handleSignup() {
        showError = false

        // Validate passwords match
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }

        let result = authService.signup(email: email, password: password)

        switch result {
        case .success:
            onSignupSuccess()
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    SignupView(onSignupSuccess: {})
}
