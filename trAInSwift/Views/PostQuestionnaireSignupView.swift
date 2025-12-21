//
//  PostQuestionnaireSignupView.swift
//  trAInSwift
//
//  Account creation screen after questionnaire completion
//  Supports Sign in with Apple and email/password signup
//

import SwiftUI
import AuthenticationServices

struct PostQuestionnaireSignupView: View {
    @ObservedObject var authService = AuthService.shared
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var acceptedTerms: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showTermsAndConditions: Bool = false
    @State private var isSigningInWithApple: Bool = false

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

                    // Sign in with Apple Button
                    Button(action: handleAppleSignIn) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18, weight: .medium))
                            Text("Sign in with Apple")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.standard)
                        .background(Color.white)
                        .cornerRadius(CornerRadius.md)
                    }
                    .padding(.horizontal, Spacing.lg)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.trainBorder)
                            .frame(height: 1)
                        Text("or")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                            .padding(.horizontal, Spacing.sm)
                        Rectangle()
                            .fill(Color.trainBorder)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, Spacing.lg)

                    // Email/Password Signup Form
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

                            Text("Min 6 chars with a number and special character")
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

                            HStack(spacing: 0) {
                                Text("I accept the ")
                                    .font(.trainBody)
                                    .foregroundColor(.trainTextPrimary)

                                Button(action: { showTermsAndConditions = true }) {
                                    Text("Terms and Conditions")
                                        .font(.trainBodyMedium)
                                        .foregroundColor(.trainPrimary)
                                        .underline()
                                }
                            }
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
                            Text("Sign Up with Email")
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
        .sheet(isPresented: $showTermsAndConditions) {
            TermsAndConditionsSheet()
        }
        .overlay {
            if isSigningInWithApple {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
    }

    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        isValidPassword(password) &&
        acceptedTerms
    }

    private func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 6 else { return false }
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:',.<>?/~`")) != nil
        return hasNumber && hasSpecial
    }

    private func handleAppleSignIn() {
        isSigningInWithApple = true
        showError = false

        authService.signInWithApple { result in
            isSigningInWithApple = false

            switch result {
            case .success(let user):
                print("✅ Apple Sign In successful:")
                print("   Email: \(user.email ?? "private")")
                print("   User ID: \(user.id?.uuidString ?? "nil")")

                // Save questionnaire data and program
                authService.updateQuestionnaireData(viewModel.questionnaireData)
                print("✅ Questionnaire data saved to user profile")

                if let program = viewModel.generatedProgram {
                    authService.updateProgram(program)
                    print("✅ Program saved to database after Apple Sign In")
                }

                onSignupSuccess()

            case .failure(let error):
                if error != .cancelled {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
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
        guard isValidPassword(password) else {
            errorMessage = "Password must be at least 6 characters with a number and special character"
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
            authService.updateQuestionnaireData(viewModel.questionnaireData)
            print("✅ Questionnaire data saved to user profile")

            if let program = viewModel.generatedProgram {
                authService.updateProgram(program)
                print("✅ Program saved to database immediately after signup")
            } else {
                print("⚠️ WARNING: No program generated yet!")
            }

            onSignupSuccess()
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Terms and Conditions Sheet

struct TermsAndConditionsSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Last Updated: December 2024")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    Group {
                        sectionHeader("1. Acceptance of Terms")
                        sectionBody("By downloading, installing, or using trAIn (\"the App\"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App.")

                        sectionHeader("2. Description of Service")
                        sectionBody("trAIn is a fitness application that provides personalized workout programs, exercise tracking, and training guidance. The App generates workout plans based on user-provided information and preferences.")

                        sectionHeader("3. User Accounts")
                        sectionBody("You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to provide accurate and complete information when creating your account.")

                        sectionHeader("4. Health and Safety Disclaimer")
                        sectionBody("The App provides general fitness information and workout suggestions. It is not a substitute for professional medical advice, diagnosis, or treatment. Always consult with a qualified healthcare provider before beginning any exercise program.\n\nYou acknowledge that physical exercise carries inherent risks. You assume full responsibility for any injuries or damages that may occur during your use of the App's workout programs.")

                        sectionHeader("5. User Content")
                        sectionBody("You retain ownership of any data you input into the App. By using the App, you grant us a license to use this data to provide and improve our services.")

                        sectionHeader("6. Prohibited Conduct")
                        sectionBody("You agree not to:\n- Use the App for any unlawful purpose\n- Attempt to gain unauthorized access to the App's systems\n- Interfere with or disrupt the App's functionality\n- Share your account with others or create multiple accounts")

                        sectionHeader("7. Intellectual Property")
                        sectionBody("The App, including its design, features, and content, is protected by intellectual property laws. You may not copy, modify, distribute, or create derivative works without our express permission.")

                        sectionHeader("8. Subscription and Payments")
                        sectionBody("Certain features may require a paid subscription. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage subscriptions in your App Store account settings.")

                        sectionHeader("9. Termination")
                        sectionBody("We reserve the right to suspend or terminate your access to the App at any time for violation of these terms or for any other reason at our discretion.")

                        sectionHeader("10. Limitation of Liability")
                        sectionBody("To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App.")

                        sectionHeader("11. Changes to Terms")
                        sectionBody("We may update these Terms and Conditions from time to time. Continued use of the App after changes constitutes acceptance of the new terms.")

                        sectionHeader("12. Contact")
                        sectionBody("If you have questions about these Terms and Conditions, please contact us through the App's support feature.")
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.trainBackground)
            .navigationTitle("Terms and Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.trainPrimary)
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.trainBodyMedium)
            .foregroundColor(.trainTextPrimary)
    }

    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(.trainBody)
            .foregroundColor(.trainTextSecondary)
    }
}

#Preview {
    PostQuestionnaireSignupView(onSignupSuccess: {
        print("Signup successful!")
    })
}

#Preview("Terms and Conditions") {
    TermsAndConditionsSheet()
}
