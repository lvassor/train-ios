//
//  DashboardCarouselView.swift
//  TrainSwift
//
//  Main dashboard carousel container with dynamic card content
//

import SwiftUI
import CoreData

struct DashboardCarouselView: View {
    let userProgram: WorkoutProgram

    @State private var carouselItems: [CarouselItem] = []
    @State private var currentPage = 0
    @State private var isCalendarExpanded = false

    // Heights for collapsed vs expanded states
    private let collapsedHeight: CGFloat = 148  // Increased to prevent TabView clipping the card border
    private let expandedHeight: CGFloat = 420

    // MARK: - Engagement Prompt Dismiss Logic

    private var shouldShowEngagementPrompt: Bool {
        let defaults = UserDefaults.standard
        guard let dismissedDate = defaults.object(forKey: "engagementPromptDismissedDate") as? Date else {
            return true // Never dismissed
        }
        // 7-day cooldown
        let daysSinceDismiss = Calendar.current.dateComponents([.day], from: dismissedDate, to: Date()).day ?? 0
        return daysSinceDismiss >= 7
    }

    private func dismissEngagementPrompt() {
        UserDefaults.standard.set(true, forKey: "engagementPromptDismissed")
        UserDefaults.standard.set(Date(), forKey: "engagementPromptDismissedDate")
        // Remove engagement prompt from carousel
        withAnimation(.easeOut(duration: AnimationDuration.standard)) {
            carouselItems.removeAll { item in
                if case .engagementPrompt = item.type { return true }
                return false
            }
        }
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Carousel - when expanded, show only the current card without TabView swiping
            if isCalendarExpanded {
                // Expanded: show current card directly without carousel behavior
                if currentPage < carouselItems.count {
                    CarouselCardView(
                        item: carouselItems[currentPage],
                        userProgram: userProgram,
                        isCalendarExpanded: $isCalendarExpanded,
                        onDismissEngagement: dismissEngagementPrompt
                    )
                    .padding(.horizontal, Spacing.xs) // Prevent edge clipping of rounded corners
                    .padding(.vertical, Spacing.xxs) // Prevent top/bottom border clipping
                }
            } else {
                // Collapsed: normal carousel with swiping
                TabView(selection: $currentPage) {
                    ForEach(Array(carouselItems.enumerated()), id: \.element.id) { index, item in
                        CarouselCardView(
                            item: item,
                            userProgram: userProgram,
                            isCalendarExpanded: $isCalendarExpanded,
                            onDismissEngagement: dismissEngagementPrompt
                        )
                        .padding(.horizontal, Spacing.xs) // Prevent edge clipping of rounded corners
                        .padding(.vertical, Spacing.xxs) // Prevent top/bottom border clipping
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .frame(height: isCalendarExpanded ? expandedHeight : collapsedHeight)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isCalendarExpanded)
        // Page indicators - outside the card, hidden when expanded
        .overlay(alignment: .bottom) {
            if carouselItems.count > 1 && !isCalendarExpanded {
                HStack(spacing: Spacing.sm) {
                    ForEach(0..<carouselItems.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.trainTextSecondary : Color.clear)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.trainTextPrimary.opacity(0.5), lineWidth: index == currentPage ? 0 : 1)
                            )
                    }
                }
                .offset(y: 24) // Position below the card
            }
        }
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

        // Add engagement prompt if not dismissed (with 7-day cooldown)
        if shouldShowEngagementPrompt, let engagementData = createEngagementPromptData() {
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
        // Collect all exercises from the user's program
        guard let program = userProgram.getProgram() else { return nil }

        let allExercises = program.sessions.flatMap { $0.exercises }
        guard let randomExercise = allExercises.randomElement() else { return nil }

        // Generate learning content based on the randomly selected exercise
        let title = randomExercise.exerciseName
        let description = "Master proper form and technique for this key exercise"

        let videoGuid = ExerciseMediaMapping.videoGuid(for: randomExercise.exerciseId)
        let thumbnailURL = ExerciseMediaMapping.thumbnailURL(for: randomExercise.exerciseId)

        return LearningRecommendationData(
            title: title,
            description: description,
            exerciseId: randomExercise.exerciseId,
            videoGuid: videoGuid,
            thumbnailURL: thumbnailURL
        )
    }

    private func createEngagementPromptData() -> EngagementPromptData? {
        let prompts = [
            ("Leave us a review!", "Help other athletes discover train"),
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
            let workoutLetter = getWorkoutLetter(for: date)
            let isCompleted = workoutLetter != nil

            days.append(DayProgress(
                weekdayLetter: weekdayLetters[i],
                isCompleted: isCompleted,
                isToday: isToday,
                workoutLetter: workoutLetter,
                date: date
            ))
        }

        return days
    }

    private func getWorkoutLetter(for date: Date) -> String? {
        guard let userId = AuthService.shared.currentUser?.id else { return nil }

        let calendar = Calendar.current
        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND completedAt >= %@ AND completedAt < %@",
            userId as CVarArg,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.fetchLimit = 1

        do {
            let sessions = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            if let session = sessions.first,
               let sessionName = session.sessionName {
                return getAbbreviation(for: sessionName)
            }
        } catch {
            AppLogger.logDatabase("Failed to fetch workout for date: \(error)", level: .error)
        }

        return nil
    }

    private func getAbbreviation(for sessionType: String) -> String {
        switch sessionType.lowercased() {
        case "push": return "P"
        case "pull": return "Pu"
        case "legs": return "L"
        case "upper", "upper body": return "U"
        case "lower", "lower body": return "Lo"
        case "full body": return "FB"
        default: return String(sessionType.prefix(1)).uppercased()
        }
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