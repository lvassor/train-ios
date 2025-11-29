//
//  PostQuestionnaireSignupView.swift
//  trAInSwift
//
//  Account creation screen after questionnaire completion
//

import SwiftUI

struct PostQuestionnaireSignupView: View {
    @ObservedObject var authService = AuthService.shared
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var acceptedTerms: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    let onSignupSuccess: () -> Void

    var body: some View {
        ScrollView {
                VStack(spacing: Spacing.xl) {
                    Spacer()
                        .frame(height: 60)

                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text("Create Your Account")
                            .font(.trainTitle)
                            .foregroundColor(.trainTextPrimary)

                        Text("Start your training journey")
                            .font(.trainSubtitle)
                            .foregroundColor(.trainTextSecondary)
                    }

                    // Signup Form
                    VStack(spacing: Spacing.lg) {
                        // Full Name
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Full Name")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextPrimary)

                            TextField("Enter your full name", text: $fullName)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding(Spacing.md)
                                .appCard()
                                .cornerRadius(CornerRadius.md)
                        }

                        // Email
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

                        // Password
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Password")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextPrimary)

                            SecureField("Create a password", text: $password)
                                .padding(Spacing.md)
                                .appCard()
                                .cornerRadius(CornerRadius.md)

                            Text("Must be at least 6 characters")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                        }

                        // Terms and Conditions
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Button(action: { acceptedTerms.toggle() }) {
                                Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundColor(acceptedTerms ? .trainPrimary : .trainBorder)
                            }

                            Text("I accept the ")
                                .font(.trainBody)
                                .foregroundColor(.trainTextPrimary)
                            +
                            Text("Terms and Conditions")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Error message
                        if showError {
                            Text(errorMessage)
                                .font(.trainCaption)
                                .foregroundColor(.red)
                                .padding(.horizontal, Spacing.sm)
                        }

                        // Sign Up Button
                        Button(action: handleSignup) {
                            Text("Sign Up")
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
        .background(Color.trainBackground.ignoresSafeArea())
    }

    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password.count >= 6 &&
        acceptedTerms
    }

    private func handleSignup() {
        showError = false

        // Name validation
        guard !fullName.isEmpty else {
            errorMessage = "Please enter your full name"
            showError = true
            return
        }

        // Basic email validation
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }

        // Password validation
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }

        // Call AuthService signup
        let result = authService.signup(email: email, password: password, name: fullName)

        switch result {
        case .success(let user):
            print("✅ Signup successful:")
            print("   Name: \(fullName)")
            print("   Email: \(email)")
            print("   User ID: \(user.id?.uuidString ?? "nil")")

            // CRITICAL: Save the questionnaire data and program immediately
            // This ensures the user has their data even if paywall fails
            authService.updateQuestionnaireData(viewModel.questionnaireData)
            print("✅ Questionnaire data saved to user profile")

            // Also save the program immediately if it exists
            if let program = viewModel.generatedProgram {
                authService.updateProgram(program)
                print("✅ Program saved to database immediately after signup")
            } else {
                print("⚠️ WARNING: No program generated yet!")
            }

            onSignupSuccess()
        case .failure(let error):
            switch error {
            case .emailAlreadyExists:
                errorMessage = "An account with this email already exists"
            case .invalidEmail:
                errorMessage = "Please enter a valid email address"
            case .passwordTooShort:
                errorMessage = "Password must be at least 6 characters"
            default:
                errorMessage = "Signup failed. Please try again."
            }
            showError = true
        }
    }
}

#Preview {
    PostQuestionnaireSignupView(onSignupSuccess: {
        print("Signup successful!")
    })
}
