//
//  WeeklyProgressCard.swift
//  TrainSwift
//
//  Weekly progress carousel card showing session completion status with expandable month view
//

import SwiftUI
import CoreData

struct WeeklyProgressCard: View {
    let data: WeeklyProgressData
    let userProgram: WorkoutProgram
    @Binding var isExpanded: Bool

    @State private var currentMonthOffset = 0 // 0 = current month, -1 = last month, etc.

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.smd) {
            // Header with expand/collapse
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(isExpanded ? currentMonthTitle : "This Week")
                        .font(.trainCaption).fontWeight(.medium)
                        .foregroundColor(.trainTextPrimary)

                    if !isExpanded {
                        Text("\(data.completedSessions)/\(data.targetSessions) Sessions Complete")
                            .font(.trainCaptionSmall).fontWeight(.light)
                            .foregroundColor(.trainTextSecondary)
                    }
                }

                Spacer()

                // Expand/collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                        if !isExpanded {
                            currentMonthOffset = 0 // Reset to current month when collapsing
                        }
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.trainCaptionSmall).fontWeight(.medium)
                        .foregroundColor(.trainTextSecondary)
                }
            }

            if isExpanded {
                // Expanded month view with horizontal scrolling
                expandedMonthView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Collapsed week row
                weekRow
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Current Month Title

    private var currentMonthTitle: String {
        let targetDate = calendar.date(byAdding: .month, value: currentMonthOffset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: targetDate)
    }

    // MARK: - Week Row (Collapsed View)

    private var weekRow: some View {
        HStack(spacing: Spacing.smd) {
            ForEach(data.days) { dayInfo in
                VStack(spacing: Spacing.sm) {
                    Text(dayInfo.weekdayLetter)
                        .font(.trainCaptionSmall).fontWeight(.light)
                        .foregroundColor(.trainTextSecondary)

                    dayCircle(for: dayInfo)
                }
            }
        }
    }

    // MARK: - Expanded Month View with Horizontal Scrolling

    private var expandedMonthView: some View {
        VStack(spacing: Spacing.smd) {
            // Month navigation
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentMonthOffset -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.trainCaption).fontWeight(.medium)
                        .foregroundColor(.trainTextPrimary)
                        .frame(width: IconSize.lg, height: IconSize.lg)
                        .background(Color.trainTextPrimary.opacity(0.1))
                        .clipShape(Circle())
                }

                Spacer()

                // Only show forward button if not at current month
                if currentMonthOffset < 0 {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentMonthOffset += 1
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.trainCaption).fontWeight(.medium)
                            .foregroundColor(.trainTextPrimary)
                            .frame(width: IconSize.lg, height: IconSize.lg)
                            .background(Color.trainTextPrimary.opacity(0.1))
                            .clipShape(Circle())
                    }
                } else {
                    // Placeholder to maintain layout
                    Color.clear
                        .frame(width: IconSize.lg, height: IconSize.lg)
                }
            }

            // Day headers (M T W T F S S)
            HStack(spacing: 0) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { letter in
                    Text(letter)
                        .font(.trainTag)
                        .foregroundColor(.trainTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Month grid
            let monthData = getMonthData()
            ForEach(0..<monthData.count, id: \.self) { weekIndex in
                HStack(spacing: 0) {
                    ForEach(monthData[weekIndex]) { dayInfo in
                        expandedDayCell(for: dayInfo)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: - Day Circle (Collapsed View)

    private func dayCircle(for dayInfo: DayProgress) -> some View {
        ZStack {
            if let workoutLetter = dayInfo.workoutLetter {
                // Completed workout - filled orange circle with letter
                Circle()
                    .fill(Color.trainPrimary)
                    .frame(width: IconSize.lg, height: IconSize.lg)

                Text(workoutLetter)
                    .font(.trainCaptionSmall).fontWeight(.bold)
                    .foregroundColor(Color(hex: "#1a1a2e"))
            } else if dayInfo.isToday {
                // Today - orange stroke ring
                Circle()
                    .stroke(Color.trainPrimary, lineWidth: 2)
                    .frame(width: IconSize.lg, height: IconSize.lg)
            } else {
                // Default - outline only
                Circle()
                    .stroke(Color.trainTextPrimary.opacity(0.3), lineWidth: 1)
                    .frame(width: IconSize.lg, height: IconSize.lg)
            }
        }
    }

    // MARK: - Expanded Day Cell

    private func expandedDayCell(for dayInfo: DayProgress) -> some View {
        let isCurrentMonth = calendar.component(.month, from: dayInfo.date) == calendar.component(.month, from: calendar.date(byAdding: .month, value: currentMonthOffset, to: Date()) ?? Date())

        return VStack(spacing: Spacing.xxs) {
            ZStack {
                if let workoutLetter = dayInfo.workoutLetter {
                    // Completed workout - filled orange circle with letter
                    Circle()
                        .fill(Color.trainPrimary)
                        .frame(width: 28, height: 28)

                    Text(workoutLetter)
                        .font(.trainMicro).fontWeight(.bold)
                        .foregroundColor(Color(hex: "#1a1a2e"))
                } else if dayInfo.isToday {
                    // Today - orange stroke ring
                    Circle()
                        .stroke(Color.trainPrimary, lineWidth: 2)
                        .frame(width: 28, height: 28)
                } else {
                    // Default - outline only
                    Circle()
                        .stroke(Color.trainTextPrimary.opacity(0.2), lineWidth: 1)
                        .frame(width: 28, height: 28)
                }
            }

            // Date number
            Text("\(calendar.component(.day, from: dayInfo.date))")
                .font(.trainMicro).fontWeight(.medium)
                .foregroundColor(.trainTextSecondary)
        }
        .opacity(isCurrentMonth ? 1.0 : 0.3)
    }

    // MARK: - Get Month Data

    private func getMonthData() -> [[DayProgress]] {
        let targetDate = calendar.date(byAdding: .month, value: currentMonthOffset, to: Date()) ?? Date()

        var weeks: [[DayProgress]] = []

        // Get first day of the month
        let components = calendar.dateComponents([.year, .month], from: targetDate)
        guard let firstOfMonth = calendar.date(from: components) else { return [] }

        // Find the Monday that starts the calendar (Monday = weekday 2)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToSubtract = (firstWeekday == 1) ? 6 : firstWeekday - 2 // If Sunday, go back 6 days
        guard let calendarStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstOfMonth) else { return [] }

        // Generate up to 6 weeks
        var currentDay = calendarStart
        for _ in 0..<6 {
            var week: [DayProgress] = []
            for _ in 0..<7 {
                week.append(getDayProgress(for: currentDay))
                currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
            }
            weeks.append(week)

            // Stop if we've passed the current month
            if calendar.component(.month, from: currentDay) != calendar.component(.month, from: firstOfMonth) {
                break
            }
        }

        return weeks
    }

    // MARK: - Get Day Progress

    private func getDayProgress(for date: Date) -> DayProgress {
        let isToday = calendar.isDateInToday(date)

        // M T W T F S S (Monday to Sunday)
        let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
        let weekday = calendar.component(.weekday, from: date)
        let weekdayLetter = weekdaySymbols[weekday - 1]

        // Check if there's a completed workout for this day
        let workoutLetter = getWorkoutLetter(for: date)

        return DayProgress(
            weekdayLetter: weekdayLetter,
            isCompleted: workoutLetter != nil,
            isToday: isToday,
            workoutLetter: workoutLetter,
            date: date
        )
    }

    // MARK: - Get Workout Letter from CoreData

    private func getWorkoutLetter(for date: Date) -> String? {
        guard let userId = AuthService.shared.currentUser?.id else { return nil }

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
            DayProgress(weekdayLetter: "M", isCompleted: true, isToday: false, workoutLetter: "P", date: Date().addingTimeInterval(-6*24*60*60)),
            DayProgress(weekdayLetter: "T", isCompleted: true, isToday: false, workoutLetter: "Pu", date: Date().addingTimeInterval(-5*24*60*60)),
            DayProgress(weekdayLetter: "W", isCompleted: false, isToday: true, date: Date()),
            DayProgress(weekdayLetter: "T", isCompleted: false, isToday: false, date: Date().addingTimeInterval(1*24*60*60)),
            DayProgress(weekdayLetter: "F", isCompleted: false, isToday: false, date: Date().addingTimeInterval(2*24*60*60)),
            DayProgress(weekdayLetter: "S", isCompleted: false, isToday: false, date: Date().addingTimeInterval(3*24*60*60)),
            DayProgress(weekdayLetter: "S", isCompleted: false, isToday: false, date: Date().addingTimeInterval(4*24*60*60))
        ]
    )

    ZStack {
        AppGradient.background
            .ignoresSafeArea()

        WeeklyProgressCard(data: sampleData, userProgram: workoutProgram, isExpanded: .constant(false))
            .padding()
    }
}
