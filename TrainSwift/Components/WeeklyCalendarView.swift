//
//  WeeklyCalendarView.swift
//  TrainSwift
//
//  Collapsible weekly/monthly calendar with workout tracking
//

import SwiftUI
import CoreData

struct WeeklyCalendarView: View {
    let userProgram: WorkoutProgram
    @State private var isExpanded = false
    @State private var currentDate = Date()

    private let calendar = Calendar.current
    private let warmSecondaryText = Color.trainTextSecondary
    private let vibrantOrange = Color.trainPrimary
    private let mutedCircleFill = Color.trainGradientEdge.opacity(0.8)

    var body: some View {
        VStack(spacing: 0) {
            // Header row with session counter
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(isExpanded ? monthYearString.uppercased() : "THIS WEEK")
                        .font(.trainTag).fontWeight(.semibold)
                        .tracking(1.5)
                        .foregroundColor(warmSecondaryText)

                    if !isExpanded {
                        Text("\(completedThisWeek)/\(Int(userProgram.daysPerWeek)) sessions complete")
                            .font(.trainMicro)
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Expand/collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.trainCaptionSmall).fontWeight(.medium)
                        .foregroundColor(warmSecondaryText)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.smd)
            .padding(.bottom, Spacing.smd)

            if isExpanded {
                // Month navigation controls
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.trainCaption).fontWeight(.medium)
                            .foregroundColor(.trainTextPrimary)
                            .frame(width: IconSize.lg, height: IconSize.lg)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.trainCaption).fontWeight(.medium)
                            .foregroundColor(.trainTextPrimary)
                            .frame(width: IconSize.lg, height: IconSize.lg)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                // Expanded month view - dynamically builds around current date
                expandedMonthView
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.smd)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Collapsed week row
                weekRow
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.smd)
            }
        }
        .appCard(cornerRadius: CornerRadius.modal)
    }

    // MARK: - Week Row

    private var weekRow: some View {
        let weekDays = getWeekDays()

        return HStack(spacing: 0) {
            ForEach(weekDays, id: \.date) { dayInfo in
                dayCircle(for: dayInfo)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Expanded Month View

    private var expandedMonthView: some View {
        let monthData = getMonthData(for: currentDate)

        return VStack(spacing: Spacing.sm) {
            // Day headers (M T W T F S S - Monday to Sunday)
            HStack(spacing: 0) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { letter in
                    Text(letter)
                        .font(.trainTag)
                        .foregroundColor(warmSecondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            // Week rows - dynamically built around current week
            ForEach(0..<monthData.count, id: \.self) { weekIndex in
                HStack(spacing: 0) {
                    ForEach(monthData[weekIndex], id: \.date) { dayInfo in
                        dayCircle(for: dayInfo, isCompact: true)
                            .frame(maxWidth: .infinity)
                            .opacity(calendar.component(.month, from: dayInfo.date) == calendar.component(.month, from: currentDate) ? 1.0 : 0.2)
                    }
                }
            }
        }
    }

    // MARK: - Day Circle

    private func dayCircle(for dayInfo: DayInfo, isCompact: Bool = false) -> some View {
        let circleSize: CGFloat = isCompact ? 36 : 44

        return VStack(spacing: isCompact ? 2 : 4) {
            // Show day letter above circle (for both collapsed and expanded views)
            Text(dayInfo.weekdayLetter)
                .font(.trainTag)
                .foregroundColor(warmSecondaryText)
                .opacity(isCompact ? 0 : 1) // Hide in expanded view (headers already shown)

            ZStack {
                if let workoutLetter = dayInfo.workoutLetter {
                    // Completed workout - solid orange filled circle with dark text
                    Circle()
                        .fill(vibrantOrange)
                        .frame(width: circleSize, height: circleSize)

                    Text(workoutLetter)
                        .font(.system(size: isCompact ? 14 : 16, weight: .bold))
                        .foregroundColor(Color.trainTextOnPrimary) // Dark background color for contrast
                } else if dayInfo.isToday {
                    // Today without workout - hollow orange ring (empty inside)
                    Circle()
                        .stroke(vibrantOrange, lineWidth: 3)
                        .frame(width: circleSize, height: circleSize)
                } else {
                    // Default - muted gray empty circle
                    Circle()
                        .fill(mutedCircleFill)
                        .frame(width: circleSize, height: circleSize)
                }
            }

            // Show date number below circle in expanded (compact) view only
            if isCompact {
                Text("\(dayInfo.day)")
                    .font(.trainCaptionSmall).fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Helper Methods

    private var completedThisWeek: Int {
        // Count how many days this week have a workout logged
        let weekDays = getWeekDays()
        return weekDays.filter { $0.workoutLetter != nil }.count
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    private func getWeekDays() -> [DayInfo] {
        var days: [DayInfo] = []
        let today = calendar.startOfDay(for: Date())

        // Find Monday of current week (Monday = 2 in calendar.weekday, Sunday = 1)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2 // If Sunday, go back 6 days; otherwise weekday - 2
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!
        let sunday = calendar.date(byAdding: .day, value: 7, to: monday)!

        // Batch-fetch all sessions for the visible week
        let sessionsByDay = batchFetchSessions(from: monday, to: sunday)

        // Generate 7 days starting from Monday
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: monday) {
                days.append(getDayInfo(for: date, sessionsByDay: sessionsByDay))
            }
        }

        return days
    }

    private func getMonthData(for date: Date) -> [[DayInfo]] {
        var weeks: [[DayInfo]] = []

        // Get first day of the month
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstOfMonth = calendar.date(from: components) else { return [] }

        // Find the Monday that starts the calendar
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToSubtract = (firstWeekday == 1) ? 6 : firstWeekday - 2 // Monday = 2, Sunday wraps to 6
        let calendarStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstOfMonth)!

        // Batch-fetch all sessions for the visible month range (up to 6 weeks = 42 days)
        let calendarEnd = calendar.date(byAdding: .day, value: 42, to: calendarStart)!
        let sessionsByDay = batchFetchSessions(from: calendarStart, to: calendarEnd)

        // Generate up to 6 weeks
        var currentDay = calendarStart
        for _ in 0..<6 {
            var week: [DayInfo] = []
            for _ in 0..<7 {
                week.append(getDayInfo(for: currentDay, sessionsByDay: sessionsByDay))
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

    private func getMonthDataAroundCurrentWeek() -> [[DayInfo]] {
        let today = calendar.startOfDay(for: Date())

        // Find the start of the current week (Monday)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2 // If Sunday, go back 6 days; otherwise weekday - 2
        guard let currentWeekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }

        // Find the start of the month
        let components = calendar.dateComponents([.year, .month], from: today)
        guard let firstOfMonth = calendar.date(from: components) else { return [] }

        // Find the Monday that starts the calendar for this month
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToSubtract = (firstWeekday == 1) ? 6 : firstWeekday - 2 // If Sunday, go back 6 days; otherwise weekday - 2
        guard let monthStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstOfMonth) else {
            return []
        }

        // Calculate how many weeks from month start to current week
        let daysBetween = calendar.dateComponents([.day], from: monthStart, to: currentWeekStart).day ?? 0
        let weeksBefore = daysBetween / 7

        // Batch-fetch all sessions for the visible range (up to 6 weeks = 42 days)
        let monthEnd = calendar.date(byAdding: .day, value: 42, to: monthStart)!
        let sessionsByDay = batchFetchSessions(from: monthStart, to: monthEnd)

        // Generate all weeks in the month
        var weeks: [[DayInfo]] = []
        var weekStart = monthStart

        for _ in 0..<6 {
            var week: [DayInfo] = []
            var dayInWeek = weekStart

            for _ in 0..<7 {
                week.append(getDayInfo(for: dayInWeek, sessionsByDay: sessionsByDay))
                dayInWeek = calendar.date(byAdding: .day, value: 1, to: dayInWeek)!
            }

            weeks.append(week)
            weekStart = calendar.date(byAdding: .day, value: 7, to: weekStart)!

            // Stop if we've passed the current month
            let nextMonth = calendar.component(.month, from: weekStart)
            let currentMonth = calendar.component(.month, from: firstOfMonth)
            if nextMonth != currentMonth && weeks.count > weeksBefore {
                break
            }
        }

        return weeks
    }

    private func getDayInfo(for date: Date, sessionsByDay: [Date: String]) -> DayInfo {
        let day = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let isCurrentMonth = true // This will be determined in the view where needed

        // M T W T F S S (Monday to Sunday)
        let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]  // Sunday=0, Monday=1, etc.
        let weekday = calendar.component(.weekday, from: date)  // 1=Sunday, 2=Monday, ..., 7=Saturday
        let weekdayLetter = weekdaySymbols[weekday - 1]

        // Look up workout letter from batch-fetched sessions
        let startOfDay = calendar.startOfDay(for: date)
        let workoutLetter = sessionsByDay[startOfDay]

        return DayInfo(
            date: date,
            day: day,
            weekdayLetter: weekdayLetter,
            isToday: isToday,
            isCurrentMonth: isCurrentMonth,
            workoutLetter: workoutLetter
        )
    }

    /// Batch-fetch all workout sessions in the given date range and return a dictionary keyed by start-of-day
    private func batchFetchSessions(from startDate: Date, to endDate: Date) -> [Date: String] {
        guard let userId = AuthService.shared.currentUser?.id else { return [:] }

        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND completedAt >= %@ AND completedAt < %@",
            userId as CVarArg,
            startDate as NSDate,
            endDate as NSDate
        )

        var sessionsByDay: [Date: String] = [:]

        do {
            let sessions = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            for session in sessions {
                guard let completedAt = session.completedAt,
                      let sessionName = session.sessionName else { continue }
                let dayKey = calendar.startOfDay(for: completedAt)
                // Keep the first session found for each day
                if sessionsByDay[dayKey] == nil {
                    sessionsByDay[dayKey] = SessionNameFormatter.abbreviation(for: sessionName)
                }
            }
        } catch {
            AppLogger.logDatabase("Failed to batch-fetch workouts: \(error)", level: .error)
        }

        return sessionsByDay
    }

}

// MARK: - Supporting Types

struct DayInfo {
    let date: Date
    let day: Int
    let weekdayLetter: String
    let isToday: Bool
    let isCurrentMonth: Bool
    let workoutLetter: String?
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

        WeeklyCalendarView(userProgram: workoutProgram)
            .padding()
    }
}
