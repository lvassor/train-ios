//
//  DashboardView.swift
//  TrainSwift
//
//  Main dashboard showing user's program and progress
//

import SwiftUI
import CoreData
import Combine

struct DashboardView: View {
    var body: some View {
        MainTabView {
            DashboardContent()
        }
    }
}

// MARK: - Dashboard Content

struct DashboardContent: View {
    @ObservedObject var authService = AuthService.shared
    @State private var showProgramOverview = false
    @State private var isProgramProgressExpanded = false
    @State private var currentStreak: Int = 0

    var user: UserProfile? {
        authService.currentUser
    }

    var userProgram: WorkoutProgram? {
        authService.getCurrentProgram()
    }

    var programData: Program? {
        userProgram?.getProgram()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient base layer - uses centralized AppGradient
                AppGradient.background
                    .ignoresSafeArea()

                // Main content - scrolls behind toolbar
                ScrollView {
                    Color.clear.frame(height: 0)
                    VStack(spacing: Spacing.lg) {
                        // Top Header (Fixed) - padding included in TopHeaderView per Figma
                        TopHeaderView()

                        // Active workout timer display
                        ActiveWorkoutTimerView()

                        if let program = userProgram {
                            // Carousel Section (contains expandable weekly progress calendar)
                            DashboardCarouselView(userProgram: program)
                                .padding(.horizontal, Spacing.lg)

                            // Split Selector and Sessions
                            WeeklySessionsSection(userProgram: program)
                                .padding(.horizontal, Spacing.lg)
                        } else {
                            // No program found - show error message
                            VStack(spacing: Spacing.lg) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.orange)

                                Text("No Training Program Found")
                                    .font(.trainTitle)
                                    .foregroundColor(.trainTextPrimary)

                                Text("There was an issue loading your program. Please contact support or restart the questionnaire.")
                                    .font(.trainBody)
                                    .foregroundColor(.trainTextSecondary)
                                    .multilineTextAlignment(.center)

                                Button(action: {
                                    authService.logout()
                                }) {
                                    Text("Log Out and Retry")
                                        .font(.trainBodyMedium)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: ElementHeight.button)
                                        .background(Color.trainPrimary)
                                        .cornerRadius(CornerRadius.md)
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.xxl)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .scrollContentBackground(.hidden)
                .edgeFadeMask(topFade: 16, bottomFade: 60)
            }
            .background(Color.clear)
            .navigationDestination(isPresented: $showProgramOverview) {
                if let program = userProgram {
                    ProgramOverviewView(userProgram: program)
                }
            }
        }
        .containerBackground(AppGradient.background, for: .navigation)
    }

    private func getUserFirstName() -> String {
        // Name now comes from the questionnaire (stored in user.name)
        if let name = user?.name, !name.isEmpty {
            let firstName = name.components(separatedBy: " ").first ?? name
            // Title case the first name
            return firstName.prefix(1).uppercased() + firstName.dropFirst().lowercased()
        }
        // Fallback should not happen as questionnaire requires a name
        return "Athlete"
    }

    private func calculateStreak() -> Int {
        guard let userId = user?.id else { return 0 }
        return SessionCompletionHelper.calculateStreak(userId: userId)
    }
}

// MARK: - Program Progress Card

struct ProgramProgressCard: View {
    let userProgram: WorkoutProgram
    @Binding var isExpanded: Bool
    let onTap: () -> Void

    var programData: Program? {
        userProgram.getProgram()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Button(action: onTap) {
                HStack {
                    Text("Your Program")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.trainTextPrimary)
                }
            }

            // Show program name (progress bar removed for MVP)
            if let validProgram = programData {
                Text(validProgram.type.description)
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)
            }

            // Expanded content
            if isExpanded, let validProgram = programData {
                VStack(spacing: Spacing.md) {
                    // Split Type Card
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Split Type")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                        Text(validProgram.type.description)
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .appCard(cornerRadius: CornerRadius.md)

                    // Duration and Frequency Cards
                    HStack(spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Duration")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                            Text("\(validProgram.totalWeeks) weeks")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                        .appCard(cornerRadius: CornerRadius.md)

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Frequency")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                            Text("\(validProgram.daysPerWeek) days/week")
                                .font(.trainBodyMedium)
                                .foregroundColor(.trainTextPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                        .appCard(cornerRadius: CornerRadius.md)
                    }

                    // Priority Muscle Groups
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Priority Muscle Groups")
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)

                        HStack(spacing: Spacing.lg) {
                            // Chest
                            VStack(spacing: Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(Color.trainPrimary.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color.trainPrimary)
                                }
                                Text("Chest")
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                            }

                            // Quads
                            VStack(spacing: Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(Color.trainPrimary.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color.trainPrimary)
                                }
                                Text("Quads")
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                            }

                            // Shoulders
                            VStack(spacing: Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(Color.trainPrimary.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color.trainPrimary)
                                }
                                Text("Shoulders")
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .appCard(cornerRadius: CornerRadius.md)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(Spacing.md)
        .appCard()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }
}

// MARK: - Weekly Sessions Section (Redesigned)

struct WeeklySessionsSection: View {
    let userProgram: WorkoutProgram
    @State private var selectedSessionIndex: Int = 0
    @ObservedObject private var authService = AuthService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            Text("Your Program")
                .font(.trainBodyMedium)
                .foregroundColor(.trainTextPrimary)

            if let programData = userProgram.getProgram() {
                let sessionsToShow = Array(programData.sessions.prefix(Int(userProgram.daysPerWeek)))
                let sessionNames = getSessionDisplayNames(sessions: sessionsToShow)

                // Ensure selectedSessionIndex is within bounds
                let safeSelectedIndex = min(selectedSessionIndex, sessionsToShow.count - 1)

                // Horizontal Day Buttons
                HorizontalDayButtonsRow(
                    sessions: sessionsToShow,
                    sessionNames: sessionNames,
                    selectedIndex: $selectedSessionIndex,
                    userProgram: userProgram
                )

                // Action Button
                SessionActionButton(
                    userProgram: userProgram,
                    sessionIndex: safeSelectedIndex,
                    isCompleted: isSessionCompleted(sessionIndex: safeSelectedIndex),
                    hasBeenCompletedThisWeek: hasSessionBeenCompletedThisWeek(sessionIndex: safeSelectedIndex)
                )

                // Dynamic Content: Exercise List or Completion Summary
                if isSessionCompleted(sessionIndex: safeSelectedIndex) {
                    CompletedSessionSummaryCard(
                        userProgram: userProgram,
                        sessionIndex: safeSelectedIndex
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if safeSelectedIndex < sessionsToShow.count {
                    ExerciseListView(
                        session: sessionsToShow[safeSelectedIndex]
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedSessionIndex)
        .onAppear {
            // Default to first incomplete session or first session
            selectedSessionIndex = nextSessionIndex ?? 0
        }
        .onChange(of: authService.currentProgramId) { _, _ in
            // Reset to first session when program changes
            selectedSessionIndex = 0
        }
    }

    private var completedThisWeek: Int {
        sessionsCompletedThisWeek.count
    }

    private var sessionsCompletedThisWeek: [CDWorkoutSession] {
        guard let userId = AuthService.shared.currentUser?.id else { return [] }
        return SessionCompletionHelper.sessionsCompletedThisWeek(userId: userId)
    }

    private var nextSessionIndex: Int? {
        for index in 0..<Int(userProgram.daysPerWeek) {
            if !isSessionCompleted(sessionIndex: index) {
                return index
            }
        }
        return nil
    }

    private func isSessionCompleted(sessionIndex: Int) -> Bool {
        guard let programData = userProgram.getProgram() else { return false }
        let sessions = Array(programData.sessions.prefix(Int(userProgram.daysPerWeek)))
        return SessionCompletionHelper.isSessionCompleted(
            sessionIndex: sessionIndex,
            sessions: sessions,
            completedSessions: sessionsCompletedThisWeek
        )
    }

    /// Check if this specific session instance has been completed this week
    private func hasSessionBeenCompletedThisWeek(sessionIndex: Int) -> Bool {
        guard let programData = userProgram.getProgram() else { return false }
        let sessions = Array(programData.sessions.prefix(Int(userProgram.daysPerWeek)))
        guard sessionIndex < sessions.count else { return false }

        let sessionName = sessions[sessionIndex].dayName
        let completedCount = sessionsCompletedThisWeek.filter { $0.sessionName == sessionName }.count
        return completedCount > 0
    }

    /// Generate display names with numbering for repeated workout types
    private func getSessionDisplayNames(sessions: [ProgramSession]) -> [(fullName: String, abbreviation: String)] {
        var nameCounts: [String: Int] = [:]
        var nameOccurrences: [String: Int] = [:]

        // First pass: count occurrences of each day name
        for session in sessions {
            nameCounts[session.dayName, default: 0] += 1
        }

        // Second pass: generate display names
        var result: [(fullName: String, abbreviation: String)] = []
        for session in sessions {
            nameOccurrences[session.dayName, default: 0] += 1
            let occurrence = nameOccurrences[session.dayName, default: 0]
            let totalCount = nameCounts[session.dayName, default: 0]

            let fullName: String
            let abbreviation: String

            if totalCount > 1 {
                // Multiple occurrences - add numbering to full name only
                fullName = "\(session.dayName) \(occurrence)"
            } else {
                fullName = session.dayName
            }

            // Generate abbreviation (never numbered)
            abbreviation = getAbbreviation(for: session.dayName)

            result.append((fullName: fullName, abbreviation: abbreviation))
        }

        return result
    }

    private func getAbbreviation(for dayName: String) -> String {
        switch dayName.lowercased() {
        case "push": return "P"
        case "pull": return "Pu"
        case "legs": return "L"
        case "upper", "upper body": return "U"
        case "lower", "lower body": return "Lo"
        case "full body": return "FB"
        default: return String(dayName.prefix(1)).uppercased()
        }
    }
}

// MARK: - Horizontal Day Buttons Row (Figma Redesign - Pill Style)

struct HorizontalDayButtonsRow: View {
    let sessions: [ProgramSession]
    let sessionNames: [(fullName: String, abbreviation: String)]
    @Binding var selectedIndex: Int
    let userProgram: WorkoutProgram

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let buttonCount = sessions.count
            let collapsedButtonWidth: CGFloat = 44
            let spacing: CGFloat = 10
            let totalSpacing = spacing * CGFloat(buttonCount - 1)
            let totalCollapsedWidth = collapsedButtonWidth * CGFloat(buttonCount - 1)
            let expandedButtonWidth = totalWidth - totalCollapsedWidth - totalSpacing

            HStack(spacing: spacing) {
                ForEach(Array(sessions.enumerated()), id: \.offset) { index, _ in
                    let isSelected = index == selectedIndex
                    let isCompleted = isSessionCompleted(sessionIndex: index)
                    let displayText = isSelected ? sessionNames[index].fullName : sessionNames[index].abbreviation

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedIndex = index
                        }
                    }) {
                        Text(displayText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSelected ? .trainBackground : (isCompleted ? .trainPrimary : .trainTextPrimary))
                            .lineLimit(1)
                            .frame(width: isSelected ? expandedButtonWidth : collapsedButtonWidth)
                            .frame(height: 44)
                            .background(
                                isSelected ? AnyShapeStyle(Color.trainTextSecondary) :
                                    (isCompleted ? AnyShapeStyle(Color.trainPrimary.opacity(0.15)) : AnyShapeStyle(.ultraThinMaterial))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        isSelected ? Color.clear :
                                            (isCompleted ? Color.trainPrimary.opacity(0.3) : Color.trainTextSecondary.opacity(0.3)),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .frame(height: 44)
    }

    private var sessionsCompletedThisWeek: [CDWorkoutSession] {
        guard let userId = AuthService.shared.currentUser?.id else { return [] }
        return SessionCompletionHelper.sessionsCompletedThisWeek(userId: userId)
    }

    private func isSessionCompleted(sessionIndex: Int) -> Bool {
        return SessionCompletionHelper.isSessionCompleted(
            sessionIndex: sessionIndex,
            sessions: sessions,
            completedSessions: sessionsCompletedThisWeek
        )
    }
}

// MARK: - Session Action Button (Figma Redesign)

struct SessionActionButton: View {
    let userProgram: WorkoutProgram
    let sessionIndex: Int
    let isCompleted: Bool
    let hasBeenCompletedThisWeek: Bool
    @ObservedObject private var workoutState = WorkoutStateManager.shared
    @ObservedObject private var authService = AuthService.shared
    @State private var showWorkoutConflict = false
    @State private var navigateToNewWorkout = false

    private var isActiveWorkout: Bool {
        guard let activeWorkout = workoutState.activeWorkout else { return false }
        return activeWorkout.sessionIndex == sessionIndex
    }

    private var buttonText: String {
        if isActiveWorkout {
            return "Continue Workout"
        } else {
            return "Start Workout"
        }
    }

    private var hasConflict: Bool {
        workoutState.isWorkoutActive && !isActiveWorkout
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Active workout indicator (if there's an active workout but it's a different session)
            if hasConflict {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("Active workout: \(workoutState.activeWorkout?.sessionName ?? "")")
                        .font(.trainCaption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
            }

            // Start/Continue Workout button
            if hasConflict {
                // Conflict: another workout is active — show warning instead of navigating
                Button(action: {
                    showWorkoutConflict = true
                }) {
                    HStack {
                        Text("Start Workout")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.trainPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            } else {
                // Normal: no conflict, navigate directly
                NavigationLink(destination: WorkoutOverviewView(
                    weekNumber: Int(userProgram.currentWeek),
                    sessionIndex: sessionIndex
                )) {
                    HStack {
                        if isActiveWorkout {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 18))
                        }
                        Text(buttonText)
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.trainPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }

            // Show View Completed Workout button below Start button if session has been completed this week
            if hasBeenCompletedThisWeek {
                NavigationLink(destination: SessionLogView(
                    userProgram: userProgram,
                    sessionIndex: sessionIndex
                )) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("View Completed Workout")
                            .font(.system(size: 16, weight: .light))
                    }
                    .foregroundColor(.trainPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.trainPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .navigationDestination(isPresented: $navigateToNewWorkout) {
            WorkoutOverviewView(
                weekNumber: Int(userProgram.currentWeek),
                sessionIndex: sessionIndex
            )
        }
        .confirmationDialog(
            "Active Workout in Progress",
            isPresented: $showWorkoutConflict,
            titleVisibility: .visible
        ) {
            Button("Abandon Current Workout", role: .destructive) {
                workoutState.cancelWorkout()
                navigateToNewWorkout = true
            }
            Button("Submit & Save Current Workout") {
                saveAndSubmitActiveWorkout()
                navigateToNewWorkout = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have an active \"\(workoutState.activeWorkout?.sessionName ?? "")\" session in progress. Please submit or abandon it before starting a new workout.")
        }
    }

    private func saveAndSubmitActiveWorkout() {
        guard let activeWorkout = workoutState.activeWorkout else { return }

        let duration = Int(Date().timeIntervalSince(activeWorkout.startTime) / 60)
        let exercisesToSave = Array(activeWorkout.loggedExercises.values).filter { logged in
            activeWorkout.completedExercises.contains(where: { id in
                (activeWorkout.modifiedExercises ?? []).first(where: { $0.id == id })?.exerciseName == logged.exerciseName
            })
        }

        if !exercisesToSave.isEmpty {
            authService.addWorkoutSession(
                sessionName: activeWorkout.sessionName,
                weekNumber: activeWorkout.weekNumber,
                exercises: exercisesToSave,
                durationMinutes: duration
            )
        }

        workoutState.completeWorkout()
    }
}

// MARK: - Exercise List View (Figma Redesign - Card Format with Video Thumbnails and Connector Line)

struct ExerciseListView: View {
    let session: ProgramSession

    // Navigation state for exercise detail
    @State private var selectedExercise: DBExercise?
    @State private var showExerciseDetail = false

    // Thumbnail width is 80, padding is 16, so center of thumbnail is at 16 + 40 = 56
    private let lineXOffset: CGFloat = 56

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section title
            Text("Workout")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.trainTextSecondary)
                .padding(.top, 8)

            // Exercise cards with vertical line behind
            ZStack(alignment: .leading) {
                // Vertical connector line - positioned at center of thumbnails
                Rectangle()
                    .fill(Color.trainTextSecondary.opacity(0.2))
                    .frame(width: 2)
                    .padding(.leading, lineXOffset - 1) // Center the 2pt line at the thumbnail center
                    .padding(.top, 48) // Start partway down the first card
                    .padding(.bottom, 48) // End partway up the last card

                // Exercise cards
                VStack(spacing: 12) {
                    ForEach(session.exercises, id: \.id) { exercise in
                        DashboardExerciseCardDarkMode(
                            exercise: exercise,
                            onTap: {
                                navigateToExerciseDetail(exercise)
                            },
                            onVideoTap: {
                                navigateToExerciseDetail(exercise)
                            }
                        )
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showExerciseDetail) {
            if let exercise = selectedExercise {
                ExerciseDemoHistoryView(exercise: exercise)
            }
        }
    }

    private func navigateToExerciseDetail(_ exercise: ProgramExercise) {
        do {
            if let dbExercise = try ExerciseDatabaseManager.shared.fetchExercise(byId: exercise.exerciseId) {
                selectedExercise = dbExercise
                showExerciseDetail = true
            }
        } catch {
            AppLogger.logDatabase("Error fetching exercise: \(error)", level: .error)
        }
    }
}

// MARK: - Completed Session Summary Card

struct CompletedSessionSummaryCard: View {
    let userProgram: WorkoutProgram
    let sessionIndex: Int

    // TODO: These would come from Core Data in a real implementation
    private var completionDate: Date {
        // Placeholder - would retrieve from stored workout session
        Date()
    }

    private var duration: String {
        // Placeholder - would calculate from stored data
        "47:20"
    }

    private var increasedReps: Int {
        // Placeholder - would calculate comparing to previous session
        12
    }

    private var increasedLoad: Double {
        // Placeholder - would calculate comparing to previous session
        25.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Completion badge
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.trainPrimary)

                Text("Workout Complete")
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                Spacer()
            }

            Divider()

            // Stats grid
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.lg) {
                    SummaryStatItem(
                        icon: "calendar",
                        label: "Completed",
                        value: formatDate(completionDate)
                    )

                    SummaryStatItem(
                        icon: "timer",
                        label: "Duration",
                        value: duration
                    )
                }

                HStack(spacing: Spacing.lg) {
                    SummaryStatItem(
                        icon: "arrow.up.circle.fill",
                        label: "Extra Reps",
                        value: "+\(increasedReps)",
                        valueColor: .trainPrimary
                    )

                    SummaryStatItem(
                        icon: "scalemass.fill",
                        label: "Extra Load",
                        value: "+\(String(format: "%.1f", increasedLoad))kg",
                        valueColor: .trainPrimary
                    )
                }
            }
        }
        .padding(Spacing.lg)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }
}

struct SummaryStatItem: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .trainTextPrimary

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.trainTextSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)

                Text(value)
                    .font(.trainBodyMedium)
                    .foregroundColor(valueColor)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}


struct SessionBubble: View {
    let sessionName: String
    let isCompleted: Bool

    var body: some View {
        HStack {
            Text(sessionName)
                .font(.trainBodyMedium)
                .foregroundColor(isCompleted ? .white : .trainTextPrimary)

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(Spacing.md)
        .background(isCompleted ? Color.trainPrimary : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

struct ExpandedSessionBubble: View {
    let sessionName: String
    let exerciseCount: Int
    let userProgram: WorkoutProgram
    let sessionIndex: Int
    @State private var navigateToWorkout = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(sessionName)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                Spacer()
            }

            Text("Next Workout")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)

            Text("\(exerciseCount) exercises")
                .font(.trainBody)
                .foregroundColor(.trainTextSecondary)

            NavigationLink(destination: WorkoutOverviewView(
                weekNumber: Int(userProgram.currentWeek),
                sessionIndex: sessionIndex
            )) {
                Text("Log this workout")
                    .font(.trainBodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.trainPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            }
        }
        .padding(Spacing.md)
        .appCard()
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Next Workout Card

struct NextWorkoutCard: View {
    let userProgram: WorkoutProgram
    let sessionIndex: Int
    let onLogWorkout: () -> Void

    var session: ProgramSession? {
        guard let program = userProgram.getProgram(),
              sessionIndex < program.sessions.count else {
            return nil
        }
        return program.sessions[sessionIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Next Workout")
                .font(.trainBodyMedium)
                .foregroundColor(.trainTextPrimary)

            if let session = session {
                Text("\(session.dayName) • \(session.exercises.count) exercises")
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)

                Button(action: onLogWorkout) {
                    Text("Log this workout")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.trainPrimary, lineWidth: 2)
                        )
                }
            } else {
                Text("Session unavailable")
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.trainBorder, lineWidth: 1)
        )
    }
}

// MARK: - Upcoming Workouts Section

struct UpcomingWorkoutsSection: View {
    let userProgram: WorkoutProgram

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(upcomingSessions) { sessionInfo in
                UpcomingWorkoutCard(
                    sessionName: sessionInfo.name,
                    exerciseCount: sessionInfo.exerciseCount
                )
            }
        }
    }

    private var sessionsCompletedThisWeek: [CDWorkoutSession] {
        guard let userId = AuthService.shared.currentUser?.id else { return [] }
        return SessionCompletionHelper.sessionsCompletedThisWeek(userId: userId)
    }

    private var upcomingSessions: [SessionInfo] {
        var upcoming: [SessionInfo] = []
        guard let programData = userProgram.getProgram() else { return [] }

        let daysPerWeek = Int(userProgram.daysPerWeek)
        let sessionsToConsider = Array(programData.sessions.prefix(daysPerWeek))

        var foundNext = false
        for (index, session) in sessionsToConsider.enumerated() {
            if !SessionCompletionHelper.isSessionCompleted(sessionIndex: index, sessions: sessionsToConsider, completedSessions: sessionsCompletedThisWeek) {
                if foundNext {
                    upcoming.append(SessionInfo(
                        id: index,
                        name: session.dayName,
                        exerciseCount: session.exercises.count
                    ))
                } else {
                    foundNext = true
                }
            }
        }

        return upcoming
    }

    struct SessionInfo: Identifiable {
        let id: Int
        let name: String
        let exerciseCount: Int
    }
}

struct UpcomingWorkoutCard: View {
    let sessionName: String
    let exerciseCount: Int

    var body: some View {
        HStack {
            Text("\(sessionName) • \(exerciseCount) exercises")
                .font(.trainBody)
                .foregroundColor(.trainTextPrimary)

            Spacer()
        }
        .padding(Spacing.md)
        .glassCompactCard(cornerRadius: 15)
    }
}

// MARK: - Bottom Navigation Bar

struct BottomNavigationBar: View {
    let onExerciseLibrary: () -> Void
    let onMilestones: () -> Void
    let onVideoLibrary: () -> Void
    let onAccount: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            BottomNavItem(
                icon: "dumbbell.fill",
                label: "Exercises",
                action: onExerciseLibrary
            )

            BottomNavItem(
                icon: "rosette",
                label: "Milestones",
                action: onMilestones
            )

            BottomNavItem(
                icon: "play.circle.fill",
                label: "Videos",
                action: onVideoLibrary
            )

            BottomNavItem(
                icon: "person.circle.fill",
                label: "Account",
                action: onAccount
            )
        }
        .frame(height: 70)
        .appCard()
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
    }
}

struct BottomNavItem: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.trainTextPrimary)

                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.trainTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Active Workout Timer View

struct ActiveWorkoutTimerView: View {
    @ObservedObject private var workoutState = WorkoutStateManager.shared
    @State private var currentTime = Date()
    @State private var timer: Timer?

    private var elapsedTimeFormatted: String {
        guard let activeWorkout = workoutState.activeWorkout else { return "00:00" }
        let elapsed = currentTime.timeIntervalSince(activeWorkout.startTime)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        if workoutState.shouldShowContinueButton {
            NavigationLink(destination: WorkoutOverviewView(
                weekNumber: workoutState.activeWorkout?.weekNumber ?? 1,
                sessionIndex: workoutState.activeWorkout?.sessionIndex ?? 0
            )) {
                HStack(spacing: Spacing.md) {
                    // Active workout indicator
                    HStack(spacing: Spacing.xs) {
                        // Pulsing dot to indicate active workout
                        Circle()
                            .fill(Color.trainTextSecondary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: currentTime)

                        Text("ACTIVE WORKOUT")
                            .font(.trainCaption)
                            .fontWeight(.semibold)
                            .foregroundColor(.trainTextSecondary)
                    }

                    Spacer()

                    // Live timer
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "timer")
                            .font(.system(size: 14))
                            .foregroundColor(.trainTextSecondary)

                        Text(elapsedTimeFormatted)
                            .font(.trainBodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.trainTextPrimary)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.trainTextSecondary.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, Spacing.lg)
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    private func startTimer() {
        timer?.invalidate() // Clear any existing timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Top Header View

struct TopHeaderView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var currentStreak: Int = 0

    var body: some View {
        HStack {
            // Streak indicator - Figma style
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 16))
                Text("\(currentStreak)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.trainTextPrimary)
            }

            Spacer()

            // App logo - centered (using cropped SVG with reduced padding)
            Image("TrainLogoWithText")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 40)

            Spacer()

            // Settings icon (replaces QR scanner per Figma)
            Button(action: {
                // TODO: Implement settings navigation
                AppLogger.logUI("Settings tapped")
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 24))
                    .foregroundColor(.trainTextPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .onAppear {
            currentStreak = calculateStreak()
        }
    }

    private func calculateStreak() -> Int {
        guard let userId = authService.currentUser?.id else { return 0 }
        return SessionCompletionHelper.calculateStreak(userId: userId)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
