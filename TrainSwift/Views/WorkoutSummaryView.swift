//
//  WorkoutSummaryView.swift
//  TrainSwift
//
//  Enhanced workout completion celebration screen with motivational feedback
//

import SwiftUI
import UIKit

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
    @State private var showMilestones = false

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
                                .font(.trainMediumNumber)
                                .padding(.top, Spacing.sm)

                            // Strong Completion Message
                            Text(content.headline)
                                .font(.trainTitle).fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.trainTextPrimary)

                            // Quick Support Message
                            Text(content.supportMessage)
                                .font(.trainBody)
                                .foregroundColor(.trainTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, Spacing.xl)
                    }

                    // Workout Summary Card
                    if !workoutStats.isEmpty {
                        VStack(spacing: Spacing.md) {
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
                        .padding(Spacing.lg)
                        .appCard()
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.trainTextPrimary.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, Spacing.lg)
                    }

                    // PB Carousel (Weight Increases Only)
                    if !personalBests.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.md) {
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

                            // Deep link to milestones
                            Button(action: { showMilestones = true }) {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "trophy.fill")
                                        .font(.trainCaption)
                                        .foregroundColor(.trainPrimary)
                                    Text("View Your Milestones")
                                        .font(.trainBodyMedium)
                                        .foregroundColor(.trainPrimary)
                                    Image(systemName: "arrow.right")
                                        .font(.trainCaptionSmall).fontWeight(.semibold)
                                        .foregroundColor(.trainPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.smd)
                                .background(Color.trainPrimary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                            }
                            .padding(.horizontal, Spacing.lg)
                            .accessibilityLabel("View Your Milestones")
                            .accessibilityHint("Opens your milestones and achievements")
                        }
                    }

                    // Streak Increase Section
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Streak Increase")
                                .font(.trainHeadline)
                                .foregroundColor(.trainTextPrimary)
                            Text(streakMessage)
                                .font(.trainBody)
                                .foregroundColor(.trainTextSecondary)
                        }
                        Spacer()
                        Text("🔥")
                            .font(.system(size: 40))
                    }
                    .padding(Spacing.lg)
                    .appCard()
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.trainTextPrimary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.lg)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Streak increase, \(streakMessage)")

                    // Streak milestone celebration
                    if let streakMilestone = streakMilestoneReached {
                        VStack(spacing: Spacing.md) {
                            Text(streakMilestone.emoji)
                                .font(.trainMediumNumber)

                            Text(streakMilestone.title)
                                .font(.trainTitle2).fontWeight(.bold)
                                .foregroundColor(.white)

                            Text(streakMilestone.message)
                                .font(.trainBody)
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.xl)
                        .background(
                            LinearGradient(
                                colors: [.trainPrimary, .trainPrimary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
                        .padding(.horizontal, Spacing.lg)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(streakMilestone.title), \(streakMilestone.message)")
                    }

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
                                .font(.system(size: IconSize.sm))
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
                    .accessibilityLabel("Share workout")
                    .accessibilityHint("Share your workout results")

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
                    .accessibilityLabel("Done")
                    .accessibilityHint("Close workout summary and return to dashboard")
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
        .onAppear {
            loadCelebrationData()
        }
        .sheet(isPresented: $showMilestones) {
            NavigationStack {
                MilestonesView()
            }
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
        // Select emoji based on context (deterministic, not random)
        let selectedEmoji: String
        let selectedHeadline: String

        if !personalBests.isEmpty {
            selectedEmoji = "🏆"
            selectedHeadline = "You hit a new PB!"
        } else if currentStreak >= 7 {
            selectedEmoji = "🔥"
            selectedHeadline = "You're on fire!"
        } else if completedExercises == totalExercises {
            selectedEmoji = "💪"
            selectedHeadline = "You smashed this workout!"
        } else {
            selectedEmoji = "⭐"
            selectedHeadline = "Another one for the books"
        }

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

    /// Check if the current streak has hit a celebration milestone (7, 30, 100 days)
    private var streakMilestoneReached: StreakMilestone? {
        let milestones: [StreakMilestone] = [
            StreakMilestone(threshold: 100, emoji: "\u{1F525}", title: "100-Day Streak!", message: "Incredible dedication! You've trained for 100 days. You're unstoppable."),
            StreakMilestone(threshold: 30, emoji: "\u{1F525}", title: "30-Day Streak!", message: "A full month of consistency. Your discipline is paying off."),
            StreakMilestone(threshold: 7, emoji: "\u{1F525}", title: "7-Day Streak!", message: "One full week of training! Great habit building.")
        ]
        return milestones.first { currentStreak >= $0.threshold && currentStreak < $0.threshold + 1 }
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
        // Compare current session reps with previous session reps for each exercise
        var totalIncrease = 0

        guard let programId = authService.getCurrentProgram()?.id?.uuidString else {
            return 0
        }

        for exercise in loggedExercises {
            guard let previousSets = authService.getPreviousSessionData(
                programId: programId,
                exerciseName: exercise.exerciseName
            ) else { continue }

            let currentReps = exercise.sets.filter { $0.completed }.reduce(0) { $0 + $1.reps }
            let previousReps = previousSets.filter { $0.completed }.reduce(0) { $0 + $1.reps }
            let diff = currentReps - previousReps
            if diff > 0 {
                totalIncrease += diff
            }
        }

        return totalIncrease
    }

    private func calculateTotalWeight() -> Double {
        return loggedExercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.completed }.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }

    private func calculateCurrentStreak() -> Int {
        guard let userId = authService.currentUser?.id else { return 0 }
        return SessionCompletionHelper.calculateStreak(userId: userId)
    }

    private func getTotalSessionCount() -> Int {
        return authService.getWorkoutHistory().count
    }

    private func getSessionsThisWeek() -> Int {
        guard let userId = authService.currentUser?.id else { return 0 }
        return SessionCompletionHelper.sessionsCompletedThisWeek(userId: userId).count
    }

    private func shareWorkout() {
        // Build PB tuples from detected personal bests
        let pbTuples = personalBests.map { pb in
            (exerciseName: pb.exerciseName,
             previousWeight: Double(pb.previousWeight),
             newWeight: Double(pb.newWeight))
        }

        // Assemble share data using the share service
        let shareData = WorkoutShareService.buildShareData(
            sessionName: sessionName,
            durationMinutes: duration,
            exercises: loggedExercises,
            pbs: pbTuples
        )

        // Present the branded share card + text via share sheet
        WorkoutShareService.presentShareSheet(data: shareData)
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

struct StreakMilestone {
    let threshold: Int
    let emoji: String
    let title: String
    let message: String
}

// MARK: - PB Card View

struct PBCardView: View {
    let pb: PersonalBest

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.smd) {
            Text(pb.exerciseName)
                .font(.trainBodyMedium).fontWeight(.semibold)
                .foregroundColor(.trainTextPrimary)

            HStack(spacing: Spacing.sm) {
                Text("\(pb.previousWeight)kg → \(pb.newWeight)kg")
                    .font(.trainHeadline).fontWeight(.bold)
                    .foregroundColor(.trainPrimary)
                Image(systemName: "arrow.up")
                    .font(.trainBody).fontWeight(.bold)
                    .foregroundColor(.trainPrimary)
            }

            Text("Best Set \(pb.bestSetSummary)")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .appCard()
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.trainPrimary.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pb.exerciseName) personal best, \(pb.previousWeight) to \(pb.newWeight) kilograms")
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