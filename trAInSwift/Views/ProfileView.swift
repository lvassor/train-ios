//
//  ProfileView.swift
//  trAInApp
//
//  User profile and settings
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared
    @State private var showLogoutConfirmation = false
    @State private var shouldRestartQuestionnaire = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationView {
            ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // User Info
                        VStack(spacing: Spacing.md) {
                            Circle()
                                .fill(Color.trainPrimary.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.trainPrimary)
                                )

                            Text(authService.currentUser?.name ?? authService.currentUser?.email ?? "")
                                .font(.trainHeadline)
                                .foregroundColor(.trainTextPrimary)

                            if let name = authService.currentUser?.name, !name.isEmpty {
                                Text(authService.currentUser?.email ?? "")
                                    .font(.trainBody)
                                    .foregroundColor(.trainTextSecondary)
                            }

                            if let user = authService.currentUser {
                                Text("Member since \(formatDate(user.createdAt ?? Date()))")
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                            }
                        }
                        .padding(.top, Spacing.xl)

                        // Program Card - First
                        ProgramCard()
                            .padding(.horizontal, Spacing.lg)

                        // Subscription Card - Second
                        SubscriptionInfoCard()
                            .padding(.horizontal, Spacing.lg)

                        // Menu Items
                        VStack(spacing: 0) {
                            ProfileMenuItem(
                                icon: "person.circle",
                                title: "Edit Profile",
                                action: { showEditProfile = true }
                            )

                            Divider()
                                .padding(.leading, 60)

                            ProfileMenuItem(
                                icon: "arrow.right.circle",
                                title: "Log Out",
                                isDestructive: true,
                                action: {
                                    showLogoutConfirmation = true
                                }
                            )

                            Divider()
                                .padding(.leading, 60)

                            ProfileMenuItem(
                                icon: "trash",
                                title: "Delete Account",
                                isDestructive: true,
                                action: {}
                            )
                        }
                        .appCard()
                        .padding(.horizontal, Spacing.lg)

                        Spacer()
                    }
                }
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial)
                .navigationTitle("Account Settings")
                .navigationBarTitleDisplayMode(.inline)
        }
        .confirmationDialog("Log Out", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                authService.logout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showSaveConfirmation = false
    @State private var hasChanges = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Profile Avatar
                    Circle()
                        .fill(Color.trainPrimary.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.trainPrimary)
                        )
                        .padding(.top, Spacing.xl)

                    // Form Fields
                    VStack(spacing: Spacing.md) {
                        // Name Field
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Full Name")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextPrimary)

                            TextField("Enter your name", text: $name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding(Spacing.md)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(CornerRadius.md)
                                .onChange(of: name) { _, _ in
                                    checkForChanges()
                                }
                        }

                        // Email Field (read-only)
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Email")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextPrimary)

                            Text(email)
                                .font(.trainBody)
                                .foregroundColor(.trainTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Spacing.md)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(CornerRadius.md)

                            Text("Email cannot be changed")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    Spacer()
                }
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.trainTextSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .foregroundColor(hasChanges ? .trainPrimary : .trainTextSecondary)
                    .disabled(!hasChanges)
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
        }
    }

    private func loadCurrentProfile() {
        if let user = authService.currentUser {
            name = user.name ?? ""
            email = user.email ?? ""
        }
    }

    private func checkForChanges() {
        guard let user = authService.currentUser else {
            hasChanges = false
            return
        }
        hasChanges = name != (user.name ?? "")
    }

    private func saveProfile() {
        guard let user = authService.currentUser else { return }
        user.name = name
        authService.updateUser(user)
        dismiss()
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : .trainPrimary)
                    .frame(width: 28)

                Text(title)
                    .font(.trainBody)
                    .foregroundColor(isDestructive ? .red : .trainTextPrimary)

                Spacer()

                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.trainTextSecondary)
                }
            }
            .padding(Spacing.md)
        }
    }
}

// MARK: - Subscription Info Card

struct SubscriptionInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Plan")
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Annual Plan")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    Text("£99.99/year")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)

                    Text("Next billing: Jan 15, 2026")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()
            }

            Button(action: {
                // Open iOS subscription management
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Manage Subscription")
                    .font(.trainBodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.trainPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(Spacing.md)
        .appCard()
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared
    @State private var showRetakeConfirmation = false
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with expand/collapse chevron
            HStack {
                Text("Your Program")
                    .font(.trainHeadline)
                    .foregroundColor(.trainTextPrimary)

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.trainTextSecondary)
                }
            }

            if !isExpanded {
                // Collapsed: Show summary
                VStack(alignment: .leading, spacing: 4) {
                    Text(authService.getCurrentProgram()?.getProgram()?.type.description ?? "No Program")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    if let program = authService.getCurrentProgram()?.getProgram() {
                        Text("\(program.daysPerWeek) days/week • \(program.sessionDuration.rawValue)")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                    }
                }
            } else {
                // Expanded: Show detailed elements with original Dashboard layout
                if let program = authService.getCurrentProgram()?.getProgram() {
                    VStack(spacing: Spacing.md) {
                        // Split Type Card
                        VStack(alignment: .center, spacing: Spacing.sm) {
                            Text("Split Type")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                            Text(program.type.description)
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md)
                        .glassCard(cornerRadius: CornerRadius.md)

                        // Duration and Frequency Cards (side by side)
                        HStack(spacing: Spacing.md) {
                            VStack(alignment: .center, spacing: Spacing.sm) {
                                Text("Session Duration")
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                                Text(getUserSessionDuration())
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.trainTextPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .glassCard(cornerRadius: CornerRadius.md)

                            VStack(alignment: .center, spacing: Spacing.sm) {
                                Text("Frequency")
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                                Text("\(program.daysPerWeek) days/week")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.trainTextPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .glassCard(cornerRadius: CornerRadius.md)
                        }

                        // Priority Muscle Groups with mini body diagrams
                        VStack(spacing: Spacing.md) {
                            Text("Priority Muscles")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: Spacing.lg) {
                                // Get muscle groups from questionnaire data
                                ForEach(getPriorityMuscleGroups(), id: \.self) { muscleGroup in
                                    VStack(spacing: Spacing.sm) {
                                        StaticMuscleView(
                                            muscleGroup: muscleGroup,
                                            gender: getUserGender(),
                                            size: 90,
                                            useUniformBaseColor: true
                                        )
                                        .frame(width: 90, height: 90)
                                        Text(muscleGroup)
                                            .font(.trainCaption)
                                            .foregroundColor(.trainTextSecondary)
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)  // Center the HStack
                        }
                        .padding(Spacing.md)
                        .glassCard(cornerRadius: CornerRadius.md)
                    }
                }
            }

            Button(action: {
                showRetakeConfirmation = true
            }) {
                Text("Retake Quiz")
                    .font(.trainBodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.trainPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(Spacing.md)
        .appCard()
        .confirmationDialog("Retake Quiz", isPresented: $showRetakeConfirmation, titleVisibility: .visible) {
            Button("Retake Quiz", role: .destructive) {
                // Log out to restart questionnaire flow
                // This will clear the user session and allow them to take the quiz again
                authService.logout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will log you out and let you retake the quiz to create a new program. Continue?")
        }
    }

    private func getPriorityMuscleGroups() -> [String] {
        // Get muscle groups from priorityMuscles NSArray
        guard let user = authService.currentUser,
              let priorityArray = user.priorityMuscles as? [String],
              !priorityArray.isEmpty else {
            // Default fallback
            return ["Chest", "Quads", "Shoulders"]
        }

        return priorityArray.prefix(3).map { muscle in
            muscle.trimmingCharacters(in: CharacterSet.whitespaces)
        }
    }

    private func getUserGender() -> MuscleSelector.BodyGender {
        // Get gender from questionnaire data
        guard let user = authService.currentUser,
              let questionnaireData = user.getQuestionnaireData() else {
            return .male // Default
        }

        switch questionnaireData.gender.lowercased() {
        case "female":
            return .female
        default:
            return .male // "male" or "other" defaults to male
        }
    }

    private func getUserSessionDuration() -> String {
        // Get session duration from questionnaire data
        guard let user = authService.currentUser,
              let questionnaireData = user.getQuestionnaireData(),
              !questionnaireData.sessionDuration.isEmpty else {
            return "45-60 min" // Default fallback
        }

        return questionnaireData.sessionDuration
    }
}

#Preview {
    ProfileView()
}
