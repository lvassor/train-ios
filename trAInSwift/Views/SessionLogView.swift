//
//  SessionLogView.swift
//  trAInSwift
//
//  Displays detailed workout log history for a completed session
//

import SwiftUI
import CoreData

struct SessionLogView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var authService = AuthService.shared

    let userProgram: WorkoutProgram
    let sessionIndex: Int
    let sessionName: String

    @State private var showEditSheet = false
    @State private var sessions: [CDWorkoutSession] = []
    @State private var currentSession: CDWorkoutSession?
    @State private var personalBests: [String: Double] = [:] // exerciseName -> max weight

    init(userProgram: WorkoutProgram, sessionIndex: Int) {
        self.userProgram = userProgram
        self.sessionIndex = sessionIndex

        // Get session name from program
        if let program = userProgram.getProgram(), sessionIndex < program.sessions.count {
            self.sessionName = program.sessions[sessionIndex].dayName
        } else {
            self.sessionName = "Workout"
        }
    }

    var body: some View {
        ZStack {
            Color.trainBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Session Summary Header
                    if let session = currentSession {
                        SessionSummaryHeader(
                            session: session,
                            previousSession: getPreviousSession()
                        )
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)
                    }

                    // Exercise Log Cards
                    if let session = currentSession {
                        ExerciseLogCardsSection(
                            session: session,
                            previousSession: getPreviousSession(),
                            personalBests: personalBests
                        )
                        .padding(.horizontal, Spacing.lg)
                    } else {
                        EmptySessionView()
                            .padding(.horizontal, Spacing.lg)
                    }

                    Spacer()
                        .frame(height: Spacing.xxl)
                }
            }
        }
        .navigationTitle(sessionName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEditSheet = true }) {
                    Text("Edit")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainPrimary)
                }
            }
        }
        .onAppear {
            loadSessions()
        }
        .sheet(isPresented: $showEditSheet) {
            EditSessionView(session: currentSession)
        }
    }

    private func loadSessions() {
        guard let userId = authService.currentUser?.id else { return }

        // Fetch all sessions of this workout type for this user
        let request = CDWorkoutSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "userId == %@ AND sessionName == %@",
            userId as CVarArg,
            sessionName
        )
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]

        do {
            sessions = try viewContext.fetch(request)
            currentSession = sessions.first
            calculatePersonalBests()
        } catch {
            print("Failed to fetch sessions: \(error)")
        }
    }

    private func getPreviousSession() -> CDWorkoutSession? {
        // Return the second most recent session (the one before current)
        guard sessions.count > 1 else { return nil }
        return sessions[1]
    }

    private func calculatePersonalBests() {
        // Calculate personal bests across all sessions of this type
        var bests: [String: Double] = [:]

        for session in sessions {
            let exercises = session.getLoggedExercises()
            for exercise in exercises {
                let maxWeight = exercise.sets.map { $0.weight }.max() ?? 0
                if let currentBest = bests[exercise.exerciseName] {
                    bests[exercise.exerciseName] = max(currentBest, maxWeight)
                } else {
                    bests[exercise.exerciseName] = maxWeight
                }
            }
        }

        personalBests = bests
    }
}

// MARK: - Session Summary Header

struct SessionSummaryHeader: View {
    let session: CDWorkoutSession
    let previousSession: CDWorkoutSession?

    private var formattedDate: String {
        guard let date = session.completedAt else { return "--/--/--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }

    private var formattedDuration: String {
        let totalSeconds = Int(session.durationSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var totalIncreasedReps: Int {
        guard let previous = previousSession else { return 0 }

        let currentExercises = session.getLoggedExercises()
        let previousExercises = previous.getLoggedExercises()

        var totalIncrease = 0

        for currentExercise in currentExercises {
            if let previousExercise = previousExercises.first(where: { $0.exerciseName == currentExercise.exerciseName }) {
                for (index, currentSet) in currentExercise.sets.enumerated() {
                    if index < previousExercise.sets.count {
                        let repDiff = currentSet.reps - previousExercise.sets[index].reps
                        if repDiff > 0 {
                            totalIncrease += repDiff
                        }
                    }
                }
            }
        }

        return totalIncrease
    }

    private var totalIncreasedLoad: Double {
        guard let previous = previousSession else { return 0 }

        let currentExercises = session.getLoggedExercises()
        let previousExercises = previous.getLoggedExercises()

        var totalIncrease: Double = 0

        for currentExercise in currentExercises {
            if let previousExercise = previousExercises.first(where: { $0.exerciseName == currentExercise.exerciseName }) {
                for (index, currentSet) in currentExercise.sets.enumerated() {
                    if index < previousExercise.sets.count {
                        let loadDiff = currentSet.weight - previousExercise.sets[index].weight
                        if loadDiff > 0 {
                            totalIncrease += loadDiff
                        }
                    }
                }
            }
        }

        return totalIncrease
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Date
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(.trainTextSecondary)
                Text(formattedDate)
                    .font(.trainBody)
                    .foregroundColor(.trainTextPrimary)
            }

            // Duration
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 16))
                    .foregroundColor(.trainTextSecondary)
                Text("Duration: \(formattedDuration)")
                    .font(.trainBody)
                    .foregroundColor(.trainTextPrimary)
            }

            // Increased reps
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.trainPrimary)
                Text("Total increased reps: \(totalIncreasedReps)")
                    .font(.trainBody)
                    .foregroundColor(.trainTextPrimary)
            }

            // Increased load
            HStack {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.trainPrimary)
                Text("Total increased load: \(String(format: "%.1f", totalIncreasedLoad))kg")
                    .font(.trainBody)
                    .foregroundColor(.trainTextPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Exercise Log Cards Section

struct ExerciseLogCardsSection: View {
    let session: CDWorkoutSession
    let previousSession: CDWorkoutSession?
    let personalBests: [String: Double]

    var body: some View {
        VStack(spacing: Spacing.md) {
            let exercises = session.getLoggedExercises()

            ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                ExerciseLogCard(
                    exercise: exercise,
                    previousExercise: getPreviousExercise(for: exercise.exerciseName),
                    isPersonalBest: checkPersonalBest(for: exercise)
                )
            }
        }
    }

    private func getPreviousExercise(for exerciseName: String) -> LoggedExercise? {
        guard let previous = previousSession else { return nil }
        return previous.getLoggedExercises().first { $0.exerciseName == exerciseName }
    }

    private func checkPersonalBest(for exercise: LoggedExercise) -> Bool {
        guard let best = personalBests[exercise.exerciseName] else { return false }
        let maxWeight = exercise.sets.map { $0.weight }.max() ?? 0
        return maxWeight >= best && maxWeight > 0
    }
}

// MARK: - Exercise Log Card

struct ExerciseLogCard: View {
    let exercise: LoggedExercise
    let previousExercise: LoggedExercise?
    let isPersonalBest: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Exercise name and PB indicator
            HStack {
                Text(exercise.exerciseName)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                Spacer()

                if isPersonalBest {
                    Image(systemName: "rosette")
                        .font(.system(size: 20))
                        .foregroundColor(.trainTextPrimary)
                }
            }

            // Sets
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                    HStack {
                        Text("Set \(index + 1):")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)

                        Text("\(Int(set.weight))kg • \(set.reps) reps")
                            .font(.trainBody)
                            .foregroundColor(.trainTextPrimary)

                        Spacer()

                        // Rep increase indicator
                        if let repIncrease = getRepIncrease(setIndex: index) {
                            Text("+\(repIncrease)")
                                .font(.trainCaption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.trainBorder, lineWidth: 1)
        )
    }

    private func getRepIncrease(setIndex: Int) -> Int? {
        guard let previous = previousExercise,
              setIndex < previous.sets.count else { return nil }

        let currentReps = exercise.sets[setIndex].reps
        let previousReps = previous.sets[setIndex].reps
        let diff = currentReps - previousReps

        return diff > 0 ? diff : nil
    }
}

// MARK: - Empty Session View

struct EmptySessionView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.trainTextSecondary)

            Text("No workout data found")
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            Text("Complete this workout to see your logged data here.")
                .font(.trainBody)
                .foregroundColor(.trainTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Edit Session View (Placeholder)

struct EditSessionView: View {
    @Environment(\.dismiss) var dismiss
    let session: CDWorkoutSession?

    var body: some View {
        NavigationView {
            ZStack {
                Color.trainBackground.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Text("Edit Workout Log")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text("Editing functionality coming soon")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)

                    Spacer()
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Edit Session")
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
}

#Preview {
    NavigationStack {
        SessionLogView(
            userProgram: WorkoutProgram(),
            sessionIndex: 0
        )
    }
}
