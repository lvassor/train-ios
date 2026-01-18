//
//  DashboardCarouselView.swift
//  trAInSwift
//
//  Main dashboard carousel container with dynamic card content
//

import SwiftUI
import CoreData

struct DashboardCarouselView: View {
    let userProgram: WorkoutProgram

    @State private var carouselItems: [CarouselItem] = []

    var body: some View {
        TabView {
            ForEach(carouselItems) { item in
                CarouselCardView(item: item, userProgram: userProgram)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 160)
        .onAppear {
            generateCarouselItems()
        }
        .onChange(of: userProgram.id) { _, _ in
            generateCarouselItems()
        }
    }

    private func generateCarouselItems() {
        var items: [CarouselItem] = []

        // Always include weekly progress card
        if let progressData = createWeeklyProgressData() {
            items.append(CarouselItem(type: .weeklyProgress(progressData)))
        }

        // Always add learning recommendation for testing
        if let learningData = createLearningRecommendationData() {
            items.append(CarouselItem(type: .learningRecommendation(learningData)))
        }

        // Always add engagement prompt for testing
        if let engagementData = createEngagementPromptData() {
            items.append(CarouselItem(type: .engagementPrompt(engagementData)))
        }

        carouselItems = items
    }

    // MARK: - Data Creators

    private func createWeeklyProgressData() -> WeeklyProgressData? {
        let completedSessions = getCompletedSessionsThisWeek()
        let targetSessions = Int(userProgram.daysPerWeek)
        let days = createDayProgressArray()

        return WeeklyProgressData(
            completedSessions: completedSessions,
            targetSessions: targetSessions,
            days: days
        )
    }

    private func createLearningRecommendationData() -> LearningRecommendationData? {
        // Get current program's first exercise for learning recommendation
        guard let program = userProgram.getProgram(),
              let firstSession = program.sessions.first,
              let firstExercise = firstSession.exercises.first else {
            return nil
        }

        // Generate learning content based on exercise
        let title = "Learn \(firstExercise.exerciseName)"
        let description = "Master proper form and technique for this exercise"

        // Use sample video GUIDs based on common exercise types
        let videoGuid = getVideoGuidForExercise(firstExercise.exerciseName)
        let thumbnailURL = BunnyConfig.videoThumbnailURL(for: videoGuid)

        return LearningRecommendationData(
            title: title,
            description: description,
            videoGuid: videoGuid,
            thumbnailURL: thumbnailURL
        )
    }

    private func getVideoGuidForExercise(_ exerciseName: String) -> String {
        // Map exercise names to video GUIDs from bunny library
        let lowercaseName = exerciseName.lowercased()

        if lowercaseName.contains("squat") {
            return "5ebb1352-dddb-41ef-9822-df5ddbca3450" // Cable Squat
        } else if lowercaseName.contains("push") || lowercaseName.contains("chest") {
            return "3c450656-f47f-4821-9bf6-be90b6e64c1e" // Incline Plyo Push-up
        } else if lowercaseName.contains("press") && lowercaseName.contains("shoulder") {
            return "dbc2bc30-cd2b-463a-a341-df34e33f4069" // Kettlebell Double Strict Press
        } else if lowercaseName.contains("curl") || lowercaseName.contains("bicep") {
            return "60ef27d7-5909-429a-a2c1-305cca4eaaf3" // Cable Biceps Curl
        } else if lowercaseName.contains("lunge") {
            return "f847fd56-7b94-45ef-b61f-be1dbdc3afa5" // Dumbbell Reverse Lunge
        } else if lowercaseName.contains("extension") || lowercaseName.contains("tricep") {
            return "5cfa4700-8e22-4cff-b3f8-c802f066ca59" // Dumbbell Lying Triceps Extension
        } else {
            // Default to a general exercise video
            return "47b5bb17-0de2-45f7-a8c7-9849ce354520" // Sled 45 degrees Deep Leg Press
        }
    }

    private func createEngagementPromptData() -> EngagementPromptData? {
        let prompts = [
            ("Leave us a review!", "Help other athletes discover trAIn"),
            ("Share your progress", "Show friends your training achievements"),
            ("Rate your experience", "Let us know how we're doing")
        ]

        let randomPrompt = prompts.randomElement() ?? prompts[0]

        return EngagementPromptData(
            title: randomPrompt.0,
            description: randomPrompt.1,
            action: {
                handleEngagementAction(title: randomPrompt.0)
            }
        )
    }

    // MARK: - Helper Methods

    private func getCompletedSessionsThisWeek() -> Int {
        guard let userId = AuthService.shared.currentUser?.id else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2

        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { return 0 }

        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND completedAt >= %@ AND completedAt < %@",
            userId as CVarArg, weekStart as NSDate, weekEnd as NSDate
        )

        do {
            let sessions = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            return sessions.count
        } catch {
            AppLogger.logDatabase("Failed to fetch completed sessions: \(error)", level: .error)
            return 0
        }
    }

    private func createDayProgressArray() -> [DayProgress] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2

        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }

        var days: [DayProgress] = []
        let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: monday) else { continue }

            let isToday = calendar.isDateInToday(date)
            let isCompleted = hasWorkoutOnDate(date)

            days.append(DayProgress(
                weekdayLetter: weekdayLetters[i],
                isCompleted: isCompleted,
                isToday: isToday
            ))
        }

        return days
    }

    private func hasWorkoutOnDate(_ date: Date) -> Bool {
        guard let userId = AuthService.shared.currentUser?.id else { return false }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND completedAt >= %@ AND completedAt < %@",
            userId as CVarArg, startOfDay as NSDate, endOfDay as NSDate
        )
        fetchRequest.fetchLimit = 1

        do {
            let sessions = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            return !sessions.isEmpty
        } catch {
            return false
        }
    }

    private func shouldShowEngagementPrompt() -> Bool {
        // Always show engagement prompt for testing - in production this should be 30% chance
        return true
    }

    private func handleEngagementAction(title: String) {
        switch title {
        case "Leave us a review!":
            openAppStoreReview()
        case "Share your progress":
            // TODO: Implement progress sharing
            print("Share progress tapped")
        case "Rate your experience":
            // TODO: Implement in-app rating
            print("Rate experience tapped")
        default:
            print("Engagement action: \(title)")
        }
    }

    private func openAppStoreReview() {
        // TODO: Implement App Store review request
        print("Opening App Store review")
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let program = Program(
        type: .pushPullLegs,
        daysPerWeek: 3,
        sessionDuration: .medium,
        sessions: [],
        totalWeeks: 8
    )
    let workoutProgram = WorkoutProgram.create(userId: UUID(), program: program, context: context)

    return ZStack {
        AppGradient.background
            .ignoresSafeArea()

        DashboardCarouselView(userProgram: workoutProgram)
            .padding()
    }
}