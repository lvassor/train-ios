//
//  WorkoutSummaryView.swift
//  trAInSwift
//
//  Enhanced workout completion celebration screen with motivational feedback
//

import SwiftUI

struct WorkoutSummaryView: View {
    let sessionName: String
    let duration: Int // in minutes
    let completedExercises: Int
    let totalExercises: Int
    let loggedExercises: [LoggedExercise]
    let onDone: () -> Void
    let onEdit: () -> Void

    @ObservedObject var authService = AuthService.shared
    @State private var celebrationContent: CelebrationContent?
    @State private var workoutStats: [WorkoutSummaryStat] = []
    @State private var personalBests: [PersonalBest] = []
    @State private var currentStreak: Int = 0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    .trainGradientLight,
                    .trainGradientMid,
                    .trainGradientDark
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Variable Emoji Reward
                    if let content = celebrationContent {
                        VStack(spacing: Spacing.lg) {
                            Text(content.emoji)
                                .font(.system(size: 48))
                                .padding(.top, 8)

                            // Strong Completion Message
                            Text(content.headline)
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.trainTextPrimary)

                            // Quick Support Message
                            Text(content.supportMessage)
                                .font(.system(size: 17))
                                .foregroundColor(.trainTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, Spacing.xl)
                    }

                    // Workout Summary Card
                    if !workoutStats.isEmpty {
                        VStack(spacing: 16) {
                            ForEach(workoutStats, id: \.label) { stat in
                                HStack {
                                    Text(stat.label)
                                        .font(.trainBody)
                                        .foregroundColor(.trainTextSecondary)
                                    Spacer()
                                    Text(stat.value)
                                        .font(.trainBodyMedium)
                                        .foregroundColor(.trainTextPrimary)
                                }
                            }
                        }
                        .padding(20)
                        .appCard()
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.trainTextPrimary.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, Spacing.lg)
                    }

                    // PB Carousel (Weight Increases Only)
                    if !personalBests.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today's Personal Bests")
                                .font(.trainHeadline)
                                .foregroundColor(.trainTextPrimary)
                                .padding(.horizontal, Spacing.lg)

                            TabView {
                                ForEach(personalBests, id: \.exerciseName) { pb in
                                    PBCardView(pb: pb)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .always))
                            .frame(height: 140)
                            .padding(.horizontal, Spacing.lg)
                        }
                    }

                    // Streak Increase Section
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Streak Increase")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.trainTextPrimary)
                            Text(streakMessage)
                                .font(.system(size: 16))
                                .foregroundColor(.trainTextSecondary)
                        }
                        Spacer()
                        Text("🔥")
                            .font(.system(size: 40))
                    }
                    .padding(20)
                    .appCard()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.trainTextPrimary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.lg)

                    Spacer().frame(height: 100)
                }
                .padding(.bottom, 100) // Room for floating buttons
            }

            // Bottom Action Buttons
            VStack {
                Spacer()

                HStack(spacing: Spacing.md) {
                    // Share Button
                    Button(action: shareWorkout) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                            Text("Share")
                                .font(.trainBodyMedium)
                        }
                        .foregroundColor(.trainTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: ButtonHeight.standard)
                        .background(Color.trainTextPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.trainTextPrimary.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Done Button
                    Button(action: onDone) {
                        Text("Done")
                            .font(.trainBodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: ButtonHeight.standard)
                            .background(Color.trainPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
        .onAppear {
            loadCelebrationData()
        }
    }

    // MARK: - Data Loading

    private func loadCelebrationData() {
        // Generate celebration content
        celebrationContent = generateCelebrationContent()

        // Calculate workout stats
        workoutStats = generateWorkoutStats()

        // Detect personal bests (weight increases only)
        personalBests = detectPersonalBests()

        // Calculate current streak
        currentStreak = calculateCurrentStreak()
    }

    private func generateCelebrationContent() -> CelebrationContent {
        let emojis = ["⭐", "🎉", "💪", "🏆", "🏋️", "💯"]
        let headlines = [
            "You smashed this workout!",
            "Another one for the books",
            "Great progress today!",
            "You're getting stronger!",
            "Outstanding effort!",
            "Fantastic session!"
        ]

        // Select emoji based on context
        var selectedEmoji = emojis.randomElement() ?? "💪"
        if !personalBests.isEmpty {
            selectedEmoji = "🏆" // Trophy for PB achievements
        } else if currentStreak >= 7 {
            selectedEmoji = "🔥" // Fire for strong streaks
        }

        // Select headline
        let selectedHeadline = headlines.randomElement() ?? "Great workout!"

        // Generate contextual support message
        let supportMessage = generateSupportMessage()

        return CelebrationContent(
            emoji: selectedEmoji,
            headline: selectedHeadline,
            supportMessage: supportMessage
        )
    }

    private func generateSupportMessage() -> String {
        let totalSessions = getTotalSessionCount()
        let sessionsThisWeek = getSessionsThisWeek()

        if totalSessions == 100 {
            return "That's your 100th workout!"
        } else if totalSessions % 50 == 0 {
            return "That's your \(totalSessions)th workout!"
        } else if sessionsThisWeek == 1 {
            return "First workout of the week"
        } else if sessionsThisWeek >= 3 {
            return "\(sessionsThisWeek) sessions this week!"
        } else {
            return "\(sessionsThisWeek) sessions this week"
        }
    }

    private func generateWorkoutStats() -> [WorkoutSummaryStat] {
        let durationFormatted = formatDuration(duration)
        let totalRepsIncrease = calculateRepsIncrease()
        let totalWeightLifted = calculateTotalWeight()

        return [
            WorkoutSummaryStat(label: "Total Duration", value: durationFormatted),
            WorkoutSummaryStat(label: "Increased Reps", value: "+\(totalRepsIncrease)"),
            WorkoutSummaryStat(label: "Weight Lifted", value: "\(Int(totalWeightLifted)) kg")
        ]
    }

    private func detectPersonalBests() -> [PersonalBest] {
        var pbs: [PersonalBest] = []

        guard let userId = authService.currentUser?.id else { return pbs }

        for exercise in loggedExercises {
            guard let previousData = authService.getPreviousSessionData(
                programId: authService.getCurrentProgram()?.id?.uuidString ?? "",
                exerciseName: exercise.exerciseName
            ) else { continue }

            // Check for weight increases only (as specified)
            for (index, currentSet) in exercise.sets.enumerated() {
                guard index < previousData.count else { continue }
                let previousSet = previousData[index]

                if currentSet.completed && currentSet.weight > previousSet.weight {
                    let bestSet = exercise.sets.filter { $0.completed }
                        .max(by: { $0.weight < $1.weight })

                    if let bestSet = bestSet {
                        let pb = PersonalBest(
                            exerciseName: exercise.exerciseName,
                            previousWeight: Int(previousSet.weight),
                            newWeight: Int(currentSet.weight),
                            bestSetSummary: "\(bestSet.reps) × \(Int(bestSet.weight))kg"
                        )
                        pbs.append(pb)
                        break // Only one PB per exercise
                    }
                }
            }
        }

        return pbs
    }

    // MARK: - Computed Properties

    private var streakMessage: String {
        if currentStreak == 1 {
            return "You're on a 1-day streak!"
        } else {
            return "You're on a \(currentStreak)-day streak!"
        }
    }

    // MARK: - Helper Functions

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins) min"
        }
    }

    private func calculateRepsIncrease() -> Int {
        // Mock calculation - in real app, compare with previous session
        return loggedExercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.completed }.count * 2 // Approximate increase
        }
    }

    private func calculateTotalWeight() -> Double {
        return loggedExercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.completed }.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }

    private func calculateCurrentStreak() -> Int {
        // Mock implementation - replace with actual streak calculation
        return Int.random(in: 1...14)
    }

    private func getTotalSessionCount() -> Int {
        // Mock implementation - replace with actual session count
        return Int.random(in: 10...200)
    }

    private func getSessionsThisWeek() -> Int {
        // Mock implementation - replace with actual weekly count
        return Int.random(in: 1...5)
    }

    private func shareWorkout() {
        // TODO: Implement share functionality
        print("📤 Sharing workout results")
    }
}

// MARK: - Data Models

struct CelebrationContent {
    let emoji: String
    let headline: String
    let supportMessage: String
}

struct WorkoutSummaryStat {
    let label: String
    let value: String
}

struct PersonalBest {
    let exerciseName: String
    let previousWeight: Int
    let newWeight: Int
    let bestSetSummary: String
}

// MARK: - PB Card View

struct PBCardView: View {
    let pb: PersonalBest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(pb.exerciseName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.trainTextPrimary)

            HStack(spacing: 8) {
                Text("\(pb.previousWeight)kg → \(pb.newWeight)kg")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.trainPrimary)
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.trainPrimary)
            }

            Text("Best Set \(pb.bestSetSummary)")
                .font(.system(size: 15))
                .foregroundColor(.trainTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .appCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.trainPrimary.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    WorkoutSummaryView(
        sessionName: "Push Day",
        duration: 45,
        completedExercises: 5,
        totalExercises: 5,
        loggedExercises: [
            LoggedExercise(
                exerciseName: "Bench Press",
                sets: [
                    LoggedSet(reps: 10, weight: 80, completed: true),
                    LoggedSet(reps: 9, weight: 80, completed: true),
                    LoggedSet(reps: 8, weight: 80, completed: true)
                ],
                notes: ""
            ),
            LoggedExercise(
                exerciseName: "Shoulder Press",
                sets: [
                    LoggedSet(reps: 12, weight: 40, completed: true),
                    LoggedSet(reps: 10, weight: 40, completed: true),
                    LoggedSet(reps: 10, weight: 40, completed: true)
                ],
                notes: ""
            )
        ],
        onDone: {},
        onEdit: {}
    )
    .environmentObject(ThemeManager())
}