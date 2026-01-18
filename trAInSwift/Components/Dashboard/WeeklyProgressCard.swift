//
//  WeeklyProgressCard.swift
//  trAInSwift
//
//  Weekly progress carousel card showing session completion status - different content from calendar
//

import SwiftUI
import CoreData

struct WeeklyProgressCard: View {
    let data: WeeklyProgressData
    let userProgram: WorkoutProgram

    private let warmSecondaryText = Color.trainTextSecondary
    private let vibrantOrange = Color.trainPrimary
    private let mutedCircleFill = Color.trainGradientEdge.opacity(0.8)

    var body: some View {
        VStack(spacing: 12) {
            // Header matching WeeklyCalendarView style
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("THIS WEEK")
                        .font(.system(size: 11, weight: .semibold, design: .default))
                        .tracking(1.5)
                        .foregroundColor(warmSecondaryText)

                    Text("\(data.completedSessions)/\(data.targetSessions) sessions complete")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Week row with connecting lines
            ZStack {
                // Connecting lines between completed workouts
                HStack(spacing: 0) {
                    ForEach(Array(data.days.enumerated()), id: \.offset) { index, dayInfo in
                        if index < data.days.count - 1 {
                            let nextDay = data.days[index + 1]
                            Rectangle()
                                .fill(dayInfo.isCompleted && nextDay.isCompleted ? vibrantOrange.opacity(0.3) : Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
                .padding(.top, 32) // Position lines at circle level

                // Day circles
                HStack(spacing: 0) {
                    ForEach(Array(data.days.enumerated()), id: \.offset) { index, dayInfo in
                        VStack(spacing: 4) {
                            // Show day letter above circle
                            Text(dayInfo.weekdayLetter)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(warmSecondaryText)

                            ZStack {
                                if dayInfo.isCompleted {
                                    // Completed workout - solid orange filled circle
                                    Circle()
                                        .fill(vibrantOrange)
                                        .frame(width: 44, height: 44)
                                    Text(getWorkoutLetter(for: index))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(hex: "#1a1a2e") ?? .black)
                                } else if dayInfo.isToday {
                                    // Today without workout - hollow orange ring
                                    Circle()
                                        .stroke(vibrantOrange, lineWidth: 3)
                                        .frame(width: 44, height: 44)
                                } else {
                                    // Default - muted gray empty circle
                                    Circle()
                                        .fill(mutedCircleFill)
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }

    private func getWorkoutLetter(for dayIndex: Int) -> String {
        // Simple workout letter mapping
        switch dayIndex {
        case 0: return "P"  // Monday - Push
        case 2: return "L"  // Wednesday - Legs
        case 4: return "Pu" // Friday - Pull
        default: return "W" // Workout
        }
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

    let sampleData = WeeklyProgressData(
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

    ZStack {
        AppGradient.background
            .ignoresSafeArea()

        WeeklyProgressCard(data: sampleData, userProgram: workoutProgram)
            .appCard()
            .padding()
    }
}