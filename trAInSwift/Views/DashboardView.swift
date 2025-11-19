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
                                        .font(.trainTitle)
                                        .foregroundColor(.trainTextPrimary)

                                    Text("You're killing it this week")
                                        .font(.trainBody)
                                        .foregroundColor(.trainTextSecondary)
                                }

                                Spacer()

                                // Streak counter
                                HStack(spacing: 4) {
                                    Text("🔥")
                                        .font(.system(size: 20))

                                    Text("\(currentStreak)")
                                        .font(.trainBodyMedium)
                                        .foregroundColor(.trainTextPrimary)
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)
                            .onAppear {
                                currentStreak = calculateStreak()
                            }

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

                                // Upcoming Workouts
                                UpcomingWorkoutsSection(userProgram: program)
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
            return name.components(separatedBy: " ").first ?? name
        }
        // Fall back to email
        guard let email = user?.email else { return "User" }
        return email.components(separatedBy: "@").first?.capitalized ?? "User"
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
                    Text("Program Progress")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.trainTextPrimary)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Show program name instead of week counter
                if let validProgram = programData {
                    Text(validProgram.type.description)
                        .font(.trainTitle2)
                        .foregroundColor(.trainTextPrimary)
                }

                // Progress bar (no week counter visible, just the bar)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.trainTextSecondary.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.trainPrimary)
                            .frame(
                                width: geometry.size.width * CGFloat(userProgram.currentWeek) / CGFloat(userProgram.totalWeeks),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
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
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.black, lineWidth: 2)
                    )

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

// MARK: - Weekly Sessions Section

struct WeeklySessionsSection: View {
    let userProgram: WorkoutProgram

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Weekly Sessions")
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                Text("\(completedThisWeek)/\(Int(userProgram.daysPerWeek)) complete")
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
            }

            VStack(spacing: Spacing.sm) {
                // Only show sessions up to daysPerWeek (e.g., 3 for PPL, 4 for ULUL)
                if let programData = userProgram.getProgram() {
                    let sessionsToShow = Array(programData.sessions.prefix(Int(userProgram.daysPerWeek)))
                    ForEach(Array(sessionsToShow.enumerated()), id: \.offset) { index, session in
                    let isNextSession = index == nextSessionIndex

                    if isNextSession {
                        // Expanded session with log button
                        ExpandedSessionBubble(
                            sessionName: session.dayName,
                            exerciseCount: session.exercises.count,
                            userProgram: userProgram,
                            sessionIndex: index
                        )
                    } else {
                        // Regular session bubble
                        SessionBubble(
                            sessionName: session.dayName,
                            isCompleted: isSessionCompleted(sessionIndex: index)
                        )
                    }
                    }
                }
            }
        }
    }

    private var completedThisWeek: Int {
        let currentWeekSessions = userProgram.completedSessionsSet.filter { sessionId in
            sessionId.hasPrefix("week\(userProgram.currentWeek)-")
        }
        return currentWeekSessions.count
    }

    private var nextSessionIndex: Int? {
        // Find first incomplete session within daysPerWeek limit
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
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(isCompleted ? Color.clear : Color.trainBorder, lineWidth: 1)
        )
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
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.trainBorder, lineWidth: 1)
        )
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
        let sessions = programData.sessions

        // Find first incomplete session
        var foundNext = false
        for (index, session) in sessions.enumerated() {
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
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.trainBorder, lineWidth: 1)
        )
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
