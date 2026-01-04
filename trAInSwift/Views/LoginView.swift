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
    @State private var showEmailLogin: Bool = false
    @State private var isSigningInWithApple: Bool = false
    @State private var isSigningInWithGoogle: Bool = false

    var onLoginSuccess: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Back button row
                if onBack != nil {
                    HStack {
                        Button(action: { onBack?() }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Back")
                                    .font(.trainBodyMedium)
                            }
                            .foregroundColor(.trainTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                } else {
                    Spacer()
                        .frame(height: 60)
                }

                // Logo/Title
                VStack(spacing: Spacing.md) {
                    Text("trAIn.")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.trainPrimary)

                    Text("Welcome Back")
                        .font(.trainSubtitle)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()
                    .frame(height: 40)

                VStack(spacing: Spacing.lg) {
                    // Log in with Apple Button
                    Button(action: handleAppleSignIn) {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18, weight: .medium))
                            Text("Log in with Apple")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.standard)
                        .background(Color.white)
                        .cornerRadius(CornerRadius.md)
                    }

                    // Log in with Google Button
                    Button(action: handleGoogleSignIn) {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "globe")
                                .font(.system(size: 18, weight: .medium))
                            Text("Log in with Google")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.standard)
                        .background(Color.white)
                        .cornerRadius(CornerRadius.md)
                    }

                    // Continue with Email Button
                    Button(action: { showEmailLogin = true }) {
                        Text("Continue with Email")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: ButtonHeight.standard)
                            .background(Color.trainPrimary)
                            .cornerRadius(CornerRadius.md)
                    }

                    // OR Divider
                    HStack {
                        Rectangle()
                            .fill(Color.trainBorder.opacity(0.3))
                            .frame(height: 1)
                        Text("OR")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .padding(.horizontal, Spacing.md)
                        Rectangle()
                            .fill(Color.trainBorder.opacity(0.3))
                            .frame(height: 1)
                    }

                    // Sign Up Button for new users
                    Button(action: { showSignup = true }) {
                        Text("Sign up")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.trainTextSecondary)
                            .underline()
                    }
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            // Dismiss keyboard when tapping outside text fields
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .charcoalGradientBackground()
        .sheet(isPresented: $showSignup) {
            SignupView(onSignupSuccess: {
                showSignup = false
                onLoginSuccess?()
            })
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetRequestView()
        }
        .sheet(isPresented: $showEmailLogin) {
            EmailLoginSheet(
                onLoginSuccess: {
                    showEmailLogin = false
                    onLoginSuccess?()
                }
            )
        }
        .overlay {
            if isSigningInWithApple || isSigningInWithGoogle {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
    }

    private func handleAppleSignIn() {
        isSigningInWithApple = true
        showError = false

        authService.signInWithApple { result in
            isSigningInWithApple = false

            switch result {
            case .success(_):
                onLoginSuccess?()
            case .failure(let error):
                if error != .cancelled {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func handleGoogleSignIn() {
        isSigningInWithGoogle = true
        showError = false

        authService.signInWithGoogle { result in
            isSigningInWithGoogle = false

            switch result {
            case .success(_):
                onLoginSuccess?()
            case .failure(let error):
                if error != .cancelled {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
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

// MARK: - Email Login Sheet

struct EmailLoginSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showPasswordReset: Bool = false

    let onLoginSuccess: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    Spacer()
                        .frame(height: 20)

                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text("Welcome Back")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextPrimary)

                        Text("Log in with your email")
                            .font(.trainSubtitle)
                            .foregroundColor(.trainTextSecondary)
                    }

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
                                .appCard()
                                .cornerRadius(CornerRadius.md)
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text("Password")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.trainTextPrimary)

                                Spacer()

                                // Disabled for MVP - password reset not fully implemented
                                // Button(action: { showPasswordReset = true }) {
                                //     Text("Forgot Password?")
                                //         .font(.trainCaption)
                                //         .foregroundColor(.trainPrimary)
                                // }
                            }

                            SecureField("Enter your password", text: $password)
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
                    }
                    .padding(.horizontal, Spacing.lg)

                    Spacer()
                }
            }
            .background(Color.trainBackground)
            .navigationTitle("Log In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.trainTextSecondary)
                }
            }
        }
        .sheet(isPresented: $showPasswordReset) {
            // PasswordResetRequestView() // Uncomment when password reset is implemented
        }
    }

    private func handleLogin() {
        showError = false

        let result = authService.login(email: email, password: password)

        switch result {
        case .success:
            dismiss()
            onLoginSuccess()
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    LoginView(onLoginSuccess: {})
}

#Preview("Email Login Sheet") {
    EmailLoginSheet(onLoginSuccess: {})
}
