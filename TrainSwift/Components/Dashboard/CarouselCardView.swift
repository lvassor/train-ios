//
//  CarouselCardView.swift
//  TrainSwift
//
//  Base carousel card component for the dashboard carousel
//

import SwiftUI
import CoreData

// MARK: - Carousel Card Data Model

struct CarouselItem: Identifiable {
    let id = UUID()
    let type: CarouselCardType
}

enum CarouselCardType {
    case weeklyProgress(WeeklyProgressData)
    case learningRecommendation(LearningRecommendationData)
    case engagementPrompt(EngagementPromptData)
}

// MARK: - Data Models

struct WeeklyProgressData {
    let completedSessions: Int
    let targetSessions: Int
    let days: [DayProgress]
}

struct DayProgress: Identifiable {
    let id = UUID()
    let weekdayLetter: String
    let isCompleted: Bool
    let isToday: Bool
    let workoutLetter: String? // Session abbreviation (P, Pu, L, etc.)
    let date: Date // For expanded view navigation

    init(weekdayLetter: String, isCompleted: Bool, isToday: Bool, workoutLetter: String? = nil, date: Date = Date()) {
        self.weekdayLetter = weekdayLetter
        self.isCompleted = isCompleted
        self.isToday = isToday
        self.workoutLetter = workoutLetter
        self.date = date
    }
}

struct LearningRecommendationData {
    let title: String
    let description: String
    let exerciseId: String
    let videoGuid: String?
    let thumbnailURL: URL?
}

struct EngagementPromptData {
    let title: String
    let description: String
    let action: (() -> Void)?
}

// MARK: - Main Carousel Card View

struct CarouselCardView: View {
    let item: CarouselItem
    let userProgram: WorkoutProgram
    @Binding var isCalendarExpanded: Bool

    var body: some View {
        Group {
            switch item.type {
            case .weeklyProgress(let data):
                WeeklyProgressCard(data: data, userProgram: userProgram, isExpanded: $isCalendarExpanded)
            case .learningRecommendation(let data):
                LearningRecommendationCard(data: data)
            case .engagementPrompt(let data):
                EngagementPromptCard(data: data)
            }
        }
        .appCard()
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

    let sampleProgressData = WeeklyProgressData(
        completedSessions: 2,
        targetSessions: 5,
        days: [
            DayProgress(weekdayLetter: "M", isCompleted: true, isToday: false),
            DayProgress(weekdayLetter: "T", isCompleted: true, isToday: false),
            DayProgress(weekdayLetter: "W", isCompleted: false, isToday: true),
            DayProgress(weekdayLetter: "T", isCompleted: false, isToday: false),
            DayProgress(weekdayLetter: "F", isCompleted: false, isToday: false),
            DayProgress(weekdayLetter: "S", isCompleted: false, isToday: false),
            DayProgress(weekdayLetter: "S", isCompleted: false, isToday: false)
        ]
    )

    let progressItem = CarouselItem(type: .weeklyProgress(sampleProgressData))

    return ZStack {
        AppGradient.background
            .ignoresSafeArea()

        CarouselCardView(item: progressItem, userProgram: workoutProgram, isCalendarExpanded: .constant(false))
            .padding()
    }
}