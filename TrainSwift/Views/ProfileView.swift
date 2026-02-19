//
//  ProfileView.swift
//  TrainSwift
//
//  User profile and settings
//

import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var authService = AuthService.shared
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var shouldRestartQuestionnaire = false
    @State private var showEditProfile = false
    @State private var showProgramSelector = false

    var body: some View {
        ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // User Info
                        VStack(spacing: Spacing.md) {
                            Circle()
                                .fill(Color.trainPrimary(theme: themeManager.activeTheme).opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.trainPrimary(theme: themeManager.activeTheme))
                                )

                            Text(authService.currentUser?.name ?? "User")
                                .font(.trainHeadline)
                                .foregroundColor(.trainTextPrimary(theme: themeManager.activeTheme))

                            if let user = authService.currentUser {
                                Text("Member since \(formatDate(user.createdAt ?? Date()))")
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary(theme: themeManager.activeTheme))
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

                            if authService.getInactivePrograms().count > 0 {
                                Divider()
                                    .padding(.leading, 60)

                                ProfileMenuItem(
                                    icon: "dumbbell",
                                    title: "Switch Program",
                                    action: { showProgramSelector = true }
                                )
                            }

                            Divider()
                                .padding(.leading, 60)

                            // Theme Toggle
                            ThemeToggleRow(themeManager: themeManager)

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
                                action: {
                                    showDeleteAccountConfirmation = true
                                }
                            )
                        }
                        .appCard()
                        .padding(.horizontal, Spacing.lg)

                        Spacer()
                    }
                }
                .scrollContentBackground(.hidden)
                .background(.thinMaterial)
                .navigationTitle("Account Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.trainPrimary)
                    }
                }
        .appThemeBackground(theme: themeManager.activeTheme)
        .confirmationDialog("Log Out", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                authService.logout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteAccountConfirmation, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                authService.deleteAccount()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account, workout history, and all associated data. This action cannot be undone.")
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showProgramSelector) {
            ProgramSelectorView()
        }
        .fullScreenCover(isPresented: $shouldRestartQuestionnaire) {
            QuestionnaireView(
                onComplete: {
                    shouldRestartQuestionnaire = false
                },
                onBack: {
                    shouldRestartQuestionnaire = false
                }
            )
            .environmentObject(WorkoutViewModel.shared)
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
    @State private var shouldRestartQuestionnaire = false
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
                retakeDebugLog("RETAKE", "button.tapped", [
                    "action": "Showing confirmation dialog"
                ])
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
            Button("Save & Retake") {
                retakeDebugLog("RETAKE", "confirmation.saveAndRetake", [
                    "action": "Saving current program and starting retake flow"
                ])

                // Current program will be automatically saved as inactive when new one is created
                // Reset questionnaire data for fresh start
                WorkoutViewModel.shared.questionnaireData = QuestionnaireData()
                retakeDebugLog("RETAKE", "questionnaireData.reset", [
                    "action": "QuestionnaireData cleared for fresh start"
                ])

                shouldRestartQuestionnaire = true
                retakeDebugLog("RETAKE", "fullScreenCover.triggering", [
                    "shouldRestartQuestionnaire": "\(shouldRestartQuestionnaire)"
                ])
            }
            Button("Discard & Retake", role: .destructive) {
                retakeDebugLog("RETAKE", "confirmation.discardAndRetake", [
                    "action": "Discarding current program and starting retake flow"
                ])

                // Delete the current program before creating new one
                if let currentProgram = authService.getCurrentProgram() {
                    let context = PersistenceController.shared.container.viewContext
                    context.delete(currentProgram)
                    try? context.save()
                    retakeDebugLog("RETAKE", "currentProgram.deleted", [:])
                }

                // Reset questionnaire data for fresh start
                WorkoutViewModel.shared.questionnaireData = QuestionnaireData()
                shouldRestartQuestionnaire = true
            }
            Button("Cancel", role: .cancel) {
                retakeDebugLog("RETAKE", "confirmation.cancelled", [:])
            }
        } message: {
            Text("Would you like to save your current program? You can switch back to it later in 'Switch Programs'.")
        }
        .fullScreenCover(isPresented: $shouldRestartQuestionnaire) {
            OnboardingFlowView(isRetake: true)
                .environmentObject(WorkoutViewModel.shared)
                .onAppear {
                    retakeDebugLog("RETAKE", "OnboardingFlowView.onAppear", [
                        "status": "✅ RETAKE FLOW STARTED - Skipping WelcomeView (isRetake=true)",
                        "isAuthenticated": "\(AuthService.shared.isAuthenticated)"
                    ])
                }
                .onDisappear {
                    retakeDebugLog("RETAKE", "OnboardingFlowView.onDisappear", [
                        "action": "Retake flow completed or dismissed"
                    ])
                    shouldRestartQuestionnaire = false
                }
        }
    }

    /// Debug logging for retake questionnaire flow
    private func retakeDebugLog(_ category: String, _ action: String, _ params: [String: String]) {
        var message = "[PROFILE-\(category)] \(action)"
        if !params.isEmpty {
            let paramString = params.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " | ")
            message += " | \(paramString)"
        }
        AppLogger.logUI(message)
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

// MARK: - Program Selector View

struct ProgramSelectorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared
    @State private var showSwitchConfirmation = false
    @State private var programToSwitch: WorkoutProgram?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Current Program
                    if let currentProgram = authService.getCurrentProgram() {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Current Program")
                                .font(.trainHeadline)
                                .foregroundColor(.trainTextPrimary)

                            ProgramSelectionCard(program: currentProgram, isActive: true)
                        }
                        .padding(.horizontal, Spacing.lg)
                    }

                    // Previous Programs
                    let inactivePrograms = authService.getInactivePrograms()
                    if !inactivePrograms.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Previous Programs")
                                .font(.trainHeadline)
                                .foregroundColor(.trainTextPrimary)

                            ForEach(inactivePrograms, id: \.id) { program in
                                ProgramSelectionCard(program: program, isActive: false) {
                                    programToSwitch = program
                                    showSwitchConfirmation = true
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    } else {
                        // No previous programs message
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.trainTextSecondary.opacity(0.5))

                            Text("No Previous Programs")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextSecondary)

                            Text("When you retake the quiz and save your current program, it will appear here.")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.xl)
                    }

                    Spacer()
                }
                .padding(.top, Spacing.xl)
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Switch Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.trainPrimary)
                }
            }
            .confirmationDialog("Switch Program", isPresented: $showSwitchConfirmation, titleVisibility: .visible) {
                Button("Switch Program") {
                    if let program = programToSwitch {
                        authService.activateProgram(program)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {
                    programToSwitch = nil
                }
            } message: {
                if let program = programToSwitch {
                    Text("Switch to '\(program.name ?? "Previous Program")'? Your current program will be saved and you can switch back later.")
                } else {
                    Text("Switch to this program?")
                }
            }
        }
    }
}

// MARK: - Program Selection Card

struct ProgramSelectionCard: View {
    let program: WorkoutProgram
    let isActive: Bool
    var onSelect: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            onSelect?()
        }) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(program.name ?? "Unknown Program")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    Spacer()

                    if isActive {
                        Text("ACTIVE")
                            .font(.trainCaption)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.trainPrimary)
                            .clipShape(Capsule())
                    } else if onSelect != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.trainTextSecondary)
                    }
                }

                HStack(spacing: Spacing.sm) {
                    Text("\(program.daysPerWeek) days/week")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)

                    Text("•")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)

                    Text(program.sessionDuration ?? "Unknown")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                }

                if let createdAt = program.createdAt {
                    Text("Created \(formatRelativeDate(createdAt))")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }

                // Progress indicator
                HStack(spacing: Spacing.sm) {
                    Text("Week \(program.currentWeek) of \(program.totalWeeks)")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    Spacer()

                    ProgressView(value: Double(program.currentWeek), total: Double(program.totalWeeks))
                        .progressViewStyle(LinearProgressViewStyle(tint: .trainPrimary))
                        .frame(width: 60)
                }
            }
            .padding(Spacing.md)
            .appCard()
        }
        .disabled(isActive || onSelect == nil)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Theme Toggle Row

struct ThemeToggleRow: View {
    @ObservedObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: themeManager.currentMode == .light ? "sun.max.fill" : "moon.fill")
                .font(.title3)
                .foregroundColor(.trainPrimary(theme: themeManager.activeTheme))
                .frame(width: 28)

            Text("Appearance")
                .font(.trainBody)
                .foregroundColor(.trainTextPrimary(theme: themeManager.activeTheme))

            Spacer()

            // Theme Picker with sun/moon icons
            Picker("Theme", selection: Binding(
                get: { themeManager.currentMode },
                set: { themeManager.setTheme($0) }
            )) {
                Image(systemName: "moon.fill").tag(AppThemeMode.dark)
                Image(systemName: "sun.max.fill").tag(AppThemeMode.light)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 100)
        }
        .padding(Spacing.md)
    }
}

#Preview {
    ProfileView()
}
