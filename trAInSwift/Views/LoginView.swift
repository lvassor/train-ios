//
//  LoginView.swift
//  trAInApp
//
//  Login screen for authentication
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSignup: Bool = false
    @State private var showPasswordReset: Bool = false

    var onLoginSuccess: (() -> Void)? = nil

    var body: some View {
        ScrollView {
                VStack(spacing: Spacing.xl) {
                    Spacer()
                        .frame(height: 60)

                    // Logo/Title
                    VStack(spacing: Spacing.md) {
                        Text("trAIn.")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.trainPrimary)

                        Text("Your AI-Powered Training Partner")
                            .font(.trainSubtitle)
                            .foregroundColor(.trainTextSecondary)
                    }

                    Spacer()
                        .frame(height: 40)

                    // Login Form
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
                                .warmGlassCard()
                                .cornerRadius(CornerRadius.md)
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text("Password")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.trainTextPrimary)

                                Spacer()

                                // Disabled for MVP - password reset not fully implemented
                                // TODO: Re-enable when password reset is properly implemented
                                // Button(action: { showPasswordReset = true }) {
                                //     Text("Forgot Password?")
                                //         .font(.trainCaption)
                                //         .foregroundColor(.trainPrimary)
                                // }
                            }

                            SecureField("Enter your password", text: $password)
                                .padding(Spacing.md)
                                .warmGlassCard()
                                .cornerRadius(CornerRadius.md)
                        }

                        if showError {
                            Text(errorMessage)
                                .font(.trainCaption)
                                .foregroundColor(.red)
                                .padding(.horizontal, Spacing.sm)
                        }

                        Button(action: handleLogin) {
                            Text("Log In")
                                .font(.trainBodyMedium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: ButtonHeight.standard)
                                .background(Color.trainPrimary)
                                .cornerRadius(CornerRadius.md)
                        }
                        .disabled(email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)

                        // Test account hint (DEBUG only)
                        #if DEBUG
                        VStack(spacing: Spacing.xs) {
                            Text("Test Account")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)

                            Text("test@test.com / password123")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.trainPrimary)
                        }
                        .padding(.top, Spacing.sm)
                        #endif
                    }
                    .padding(.horizontal, Spacing.lg)

                    // Signup Link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)

                        Button(action: { showSignup = true }) {
                            Text("Sign Up")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainPrimary)
                        }
                    }
                    .padding(.top, Spacing.md)

                    Spacer()
            }
        }
        .sheet(isPresented: $showSignup) {
            SignupView(onSignupSuccess: {
                showSignup = false
                onLoginSuccess?()
            })
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetRequestView()
        }
    }

    private func handleLogin() {
        showError = false

        let result = authService.login(email: email, password: password)

        switch result {
        case .success:
            onLoginSuccess?()
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    LoginView(onLoginSuccess: {})
}
