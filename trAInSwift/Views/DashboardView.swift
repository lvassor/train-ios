//
//  DashboardView.swift
//  trAInSwift
//
//  Main dashboard showing user's program and progress
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var showProgramOverview = false
    @State private var showCalendar = false
    @State private var showProfile = false
    @State private var showExerciseLibrary = false
    @State private var showMilestones = false
    @State private var showVideoLibrary = false
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
                Color.trainBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Main content
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Header
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hey, \(getUserFirstName())")
                                        .font(.trainHeadline)
                                        .foregroundColor(.trainTextPrimary)

                                    Text("You're killing it this week! 💪")
                                        .font(.trainBody)
                                        .foregroundColor(.trainTextSecondary)
                                }

                                Spacer()

                                // Streak counter - commented out for MVP
                                // HStack(spacing: 4) {
                                //     Text("🔥")
                                //         .font(.system(size: 20))
                                //
                                //     Text("\(currentStreak)")
                                //         .font(.trainBodyMedium)
                                //         .foregroundColor(.trainTextPrimary)
                                // }
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)
                            // .onAppear {
                            //     currentStreak = calculateStreak()
                            // }

                            if let program = userProgram {
                                // Program Progress Card
                                ProgramProgressCard(
                                    userProgram: program,
                                    isExpanded: $isProgramProgressExpanded,
                                    onTap: { isProgramProgressExpanded.toggle() }
                                )
                                .padding(.horizontal, Spacing.lg)

                                // Your Weekly Sessions
                                WeeklySessionsSection(userProgram: program)
                                    .padding(.horizontal, Spacing.lg)
                            } else {
                                // No program found - show error message
                                VStack(spacing: Spacing.lg) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 48))
                                        .foregroundColor(.orange)

                                    Text("No Training Programme Found")
                                        .font(.trainTitle)
                                        .foregroundColor(.trainTextPrimary)

                                    Text("There was an issue loading your programme. Please contact support or restart the questionnaire.")
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

                            Spacer()
                                .frame(height: 100) // Space for bottom nav
                        }
                    }

                    // Bottom Navigation Bar
                    BottomNavigationBar(
                        onExerciseLibrary: { showExerciseLibrary = true },
                        onMilestones: { showMilestones = true },
                        onVideoLibrary: { showVideoLibrary = true },
                        onAccount: { showProfile = true }
                    )
                }
            }
            .navigationDestination(isPresented: $showProgramOverview) {
                if let program = userProgram {
                    ProgramOverviewView(userProgram: program)
                }
            }
            .navigationDestination(isPresented: $showExerciseLibrary) {
                ExerciseLibraryView()
            }
            .navigationDestination(isPresented: $showMilestones) {
                MilestonesView()
            }
            .navigationDestination(isPresented: $showVideoLibrary) {
                VideoLibraryView()
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }

    private func getUserFirstName() -> String {
        // Try to use the stored name first
        if let name = user?.name, !name.isEmpty {
            let firstName = name.components(separatedBy: " ").first ?? name
            // Title case the first name
            return firstName.prefix(1).uppercased() + firstName.dropFirst().lowercased()
        }
        // Fall back to email
        guard let email = user?.email else { return "User" }
        let emailName = email.components(separatedBy: "@").first ?? "User"
        return emailName.prefix(1).uppercased() + emailName.dropFirst().lowercased()
    }

    private func calculateStreak() -> Int {
        guard let userId = user?.id else { return 0 }

        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@", userId as CVarArg
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]

        do {
            let sessions = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)

            var streak = 0
            var currentDate = Calendar.current.startOfDay(for: Date())

            for session in sessions {
                guard let sessionDate = session.completedAt else { continue }
                let normalizedSessionDate = Calendar.current.startOfDay(for: sessionDate)

                // Check if this session is on the current date we're looking for
                if Calendar.current.isDate(normalizedSessionDate, inSameDayAs: currentDate) {
                    streak += 1
                    // Move to previous day
                    currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else if normalizedSessionDate < currentDate {
                    // Gap in streak - stop counting
                    break
                }
                // If sessionDate > currentDate, skip this session (future sessions shouldn't exist but handle gracefully)
            }

            return streak
        } catch {
            AppLogger.logDatabase("Failed to calculate streak: \(error)", level: .error)
            return 0
        }
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
                    Text("Your Programme")
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
                    .glassCard(cornerRadius: CornerRadius.md)

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
                        .glassCard(cornerRadius: CornerRadius.md)

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
                        .glassCard(cornerRadius: CornerRadius.md)
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
                                        .fill(Color(hex: "FFD700").opacity(0.3))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: "FFD700"))
                                }
                                Text("Chest")
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                            }

                            // Quads
                            VStack(spacing: Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "FFD700").opacity(0.3))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: "FFD700"))
                                }
                                Text("Quads")
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                            }

                            // Shoulders
                            VStack(spacing: Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "FFD700").opacity(0.3))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: "FFD700"))
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
                    .glassCard(cornerRadius: CornerRadius.md)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(Spacing.md)
        .glassCard()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }
}

// MARK: - Weekly Sessions Section (Redesigned)

struct WeeklySessionsSection: View {
    let userProgram: WorkoutProgram
    @State private var selectedSessionIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Weekly Sessions")
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                Text("\(completedThisWeek)/\(Int(userProgram.daysPerWeek)) complete")
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
            }

            if let programData = userProgram.getProgram() {
                let sessionsToShow = Array(programData.sessions.prefix(Int(userProgram.daysPerWeek)))
                let sessionNames = getSessionDisplayNames(sessions: sessionsToShow)

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
                    sessionIndex: selectedSessionIndex,
                    isCompleted: isSessionCompleted(sessionIndex: selectedSessionIndex)
                )

                // Dynamic Content: Exercise List or Completion Summary
                if isSessionCompleted(sessionIndex: selectedSessionIndex) {
                    CompletedSessionSummaryCard(
                        userProgram: userProgram,
                        sessionIndex: selectedSessionIndex
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    ExerciseListView(
                        session: sessionsToShow[selectedSessionIndex]
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
    }

    private var completedThisWeek: Int {
        let currentWeekSessions = userProgram.completedSessionsSet.filter { sessionId in
            sessionId.hasPrefix("week\(userProgram.currentWeek)-")
        }
        return currentWeekSessions.count
    }

    private var nextSessionIndex: Int? {
        for index in 0..<Int(userProgram.daysPerWeek) {
            let sessionId = "week\(userProgram.currentWeek)-session\(index)"
            if !userProgram.completedSessionsSet.contains(sessionId) {
                return index
            }
        }
        return nil
    }

    private func isSessionCompleted(sessionIndex: Int) -> Bool {
        let sessionId = "week\(userProgram.currentWeek)-session\(sessionIndex)"
        return userProgram.completedSessionsSet.contains(sessionId)
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
            let occurrence = nameOccurrences[session.dayName]!
            let totalCount = nameCounts[session.dayName]!

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

// MARK: - Horizontal Day Buttons Row

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
            let spacing: CGFloat = Spacing.sm
            let totalSpacing = spacing * CGFloat(buttonCount - 1)
            let totalCollapsedWidth = collapsedButtonWidth * CGFloat(buttonCount - 1)
            let expandedButtonWidth = totalWidth - totalCollapsedWidth - totalSpacing

            HStack(spacing: spacing) {
                ForEach(Array(sessions.enumerated()), id: \.offset) { index, _ in
                    let isSelected = index == selectedIndex
                    let isCompleted = isSessionCompleted(sessionIndex: index)

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedIndex = index
                        }
                    }) {
                        Text(isSelected ? sessionNames[index].fullName : sessionNames[index].abbreviation)
                            .font(.trainBodyMedium)
                            .foregroundColor(isSelected ? .white : (isCompleted ? .trainPrimary : .trainTextPrimary))
                            .lineLimit(1)
                            .frame(width: isSelected ? expandedButtonWidth : collapsedButtonWidth)
                            .frame(height: 44)
                            .background(
                                isSelected ? Color.trainPrimary :
                                    (isCompleted ? Color.trainPrimary.opacity(0.15) : Color.white)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(isCompleted && !isSelected ? Color.trainPrimary.opacity(0.3) : .clear, lineWidth: 1)
                            )
                            .shadow(
                                color: isSelected ? Color.trainPrimary.opacity(0.3) : .black.opacity(0.06),
                                radius: isSelected ? 12 : 6,
                                x: 0,
                                y: isSelected ? 4 : 2
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .frame(height: 44)
    }

    private func isSessionCompleted(sessionIndex: Int) -> Bool {
        let sessionId = "week\(userProgram.currentWeek)-session\(sessionIndex)"
        return userProgram.completedSessionsSet.contains(sessionId)
    }
}

// MARK: - Session Action Button

struct SessionActionButton: View {
    let userProgram: WorkoutProgram
    let sessionIndex: Int
    let isCompleted: Bool

    var body: some View {
        if isCompleted {
            // View Completed Workout button
            NavigationLink(destination: SessionLogView(
                userProgram: userProgram,
                sessionIndex: sessionIndex
            )) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("View Completed Workout")
                        .font(.trainBodyMedium)
                }
                .foregroundColor(.trainPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.trainPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            }
        } else {
            // Start Workout button
            NavigationLink(destination: WorkoutLoggerView(
                weekNumber: Int(userProgram.currentWeek),
                sessionIndex: sessionIndex
            )) {
                Text("Start Workout")
                    .font(.trainBodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.trainPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                    .shadow(color: Color.trainPrimary.opacity(0.4), radius: 16, x: 0, y: 0)
            }
        }
    }
}

// MARK: - Exercise List View (for uncompleted sessions)

struct ExerciseListView: View {
    let session: ProgramSession

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(session.exercises) { exercise in
                HStack(spacing: Spacing.md) {
                    // Radio button circle
                    Circle()
                        .stroke(Color.trainTextSecondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.exerciseName)
                            .font(.trainBodyMedium)
                            .foregroundColor(.trainTextPrimary)

                        Text("\(exercise.sets) sets × \(exercise.repRange) reps")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)
                    }

                    Spacer()
                }
                .padding(Spacing.md)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
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
        .shadow(color: isCompleted ? Color.trainPrimary.opacity(0.4) : .black.opacity(0.08), radius: isCompleted ? 16 : 12, x: 0, y: isCompleted ? 0 : 6)
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

            NavigationLink(destination: WorkoutLoggerView(
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
                    .shadow(color: Color.trainPrimary.opacity(0.4), radius: 16, x: 0, y: 0)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
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

    private var upcomingSessions: [SessionInfo] {
        var upcoming: [SessionInfo] = []
        guard let programData = userProgram.getProgram() else { return [] }

        // CRITICAL: Only consider sessions within daysPerWeek limit
        let daysPerWeek = Int(userProgram.daysPerWeek)
        let sessionsToConsider = Array(programData.sessions.prefix(daysPerWeek))

        // Find first incomplete session
        var foundNext = false
        for (index, session) in sessionsToConsider.enumerated() {
            let sessionId = "week\(userProgram.currentWeek)-session\(index)"
            if !userProgram.completedSessionsSet.contains(sessionId) {
                if foundNext {
                    // This is an upcoming session
                    upcoming.append(SessionInfo(
                        id: index,
                        name: session.dayName,
                        exerciseCount: session.exercises.count
                    ))
                } else {
                    // This is the next session, skip it
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
        .background(Color.white)
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

// MARK: - Preview

#Preview {
    DashboardView()
}
