//
//  PostQuestionnaireSignupView.swift
//  trAInSwift
//
//  Account creation screen after questionnaire completion
//

import SwiftUI

struct PostQuestionnaireSignupView: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var acceptedTerms: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    let onSignupSuccess: () -> Void

    var body: some View {
        ZStack {
            Color.trainBackground.ignoresSafeArea()

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
                                .background(Color.white)
                                .cornerRadius(CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(Color.trainBorder, lineWidth: 1)
                                )
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
                                .background(Color.white)
                                .cornerRadius(CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(Color.trainBorder, lineWidth: 1)
                                )
                        }

                        // Password
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Password")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextPrimary)

                            SecureField("Create a password", text: $password)
                                .padding(Spacing.md)
                                .background(Color.white)
                                .cornerRadius(CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(Color.trainBorder, lineWidth: 1)
                                )

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
        }
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

        // Dummy signup - just validate and proceed
        print("📝 Dummy Signup:")
        print("   Name: \(fullName)")
        print("   Email: \(email)")
        print("   T&C Accepted: \(acceptedTerms)")

        // Proceed to next screen
        onSignupSuccess()
    }
}

#Preview {
    PostQuestionnaireSignupView(onSignupSuccess: {
        print("Signup successful!")
    })
}
