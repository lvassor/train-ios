//
//  WeeklyCalendarView.swift
//  trAInSwift
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
    private let warmSecondaryText = Color(hex: "#8A8078")
    private let vibrantOrange = Color(hex: "#FF7A00")
    private let mutedCircleFill = Color(hex: "#3D2A1A").opacity(0.8)

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text(isExpanded ? monthYearString.uppercased() : "THIS WEEK")
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .tracking(1.5)
                    .foregroundColor(warmSecondaryText)

                Spacer()

                // Expand/collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(warmSecondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)

            if isExpanded {
                // Expanded month view - dynamically builds around current week
                expandedMonthView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Collapsed week row
                weekRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
        }
        .appCard(cornerRadius: 20)
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
        let monthData = getMonthDataAroundCurrentWeek()

        return VStack(spacing: 8) {
            // Day headers (S M T W T F S)
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 11, weight: .medium))
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
                            .opacity(dayInfo.isCurrentMonth ? 1.0 : 0.2)
                    }
                }
            }
        }
    }

    // MARK: - Day Circle

    private func dayCircle(for dayInfo: DayInfo, isCompact: Bool = false) -> some View {
        let circleSize: CGFloat = isCompact ? 36 : 44

        return VStack(spacing: isCompact ? 2 : 4) {
            if !isCompact {
                Text(dayInfo.weekdayLetter)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(warmSecondaryText)
            }

            ZStack {
                if let workoutLetter = dayInfo.workoutLetter {
                    // Completed workout - solid orange with letter
                    Circle()
                        .fill(vibrantOrange)
                        .frame(width: circleSize, height: circleSize)

                    Text(workoutLetter)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else if dayInfo.isToday {
                    // Today - hollow orange ring
                    Circle()
                        .stroke(vibrantOrange, lineWidth: 3)
                        .frame(width: circleSize, height: circleSize)
                } else {
                    // Default - muted gray fill
                    Circle()
                        .fill(mutedCircleFill)
                        .frame(width: circleSize, height: circleSize)
                }
            }

            if !isCompact {
                Text("\(dayInfo.day)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
            } else {
                Text("\(dayInfo.day)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Helper Methods

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    private func getWeekDays() -> [DayInfo] {
        var days: [DayInfo] = []
        let today = calendar.startOfDay(for: Date())

        // Find Wednesday of current week
        let weekday = calendar.component(.weekday, from: today)
        let daysFromWednesday = (weekday + 4) % 7 // Adjust to get Wednesday
        let wednesday = calendar.date(byAdding: .day, value: -daysFromWednesday, to: today)!

        // Generate 7 days starting from Wednesday
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: wednesday) {
                days.append(getDayInfo(for: date))
            }
        }

        return days
    }

    private func getMonthData() -> [[DayInfo]] {
        var weeks: [[DayInfo]] = []

        // Get first day of the month
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstOfMonth = calendar.date(from: components) else { return [] }

        // Find the Sunday that starts the calendar
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToSubtract = (firstWeekday - 1) // Sunday = 1
        let calendarStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstOfMonth)!

        // Generate up to 6 weeks
        var currentDay = calendarStart
        for _ in 0..<6 {
            var week: [DayInfo] = []
            for _ in 0..<7 {
                week.append(getDayInfo(for: currentDay))
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

        // Find the start of the current week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1 // Sunday = 1
        guard let currentWeekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: today) else {
            return []
        }

        // Find the start of the month
        let components = calendar.dateComponents([.year, .month], from: today)
        guard let firstOfMonth = calendar.date(from: components) else { return [] }

        // Find the Sunday that starts the calendar for this month
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToSubtract = (firstWeekday - 1)
        guard let monthStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstOfMonth) else {
            return []
        }

        // Calculate how many weeks from month start to current week
        let daysBetween = calendar.dateComponents([.day], from: monthStart, to: currentWeekStart).day ?? 0
        let weeksBefore = daysBetween / 7

        // Generate all weeks in the month
        var weeks: [[DayInfo]] = []
        var weekStart = monthStart

        for _ in 0..<6 {
            var week: [DayInfo] = []
            var dayInWeek = weekStart

            for _ in 0..<7 {
                week.append(getDayInfo(for: dayInWeek))
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

    private func getDayInfo(for date: Date) -> DayInfo {
        let day = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let isCurrentMonth = calendar.component(.month, from: date) == calendar.component(.month, from: currentDate)

        let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
        let weekday = calendar.component(.weekday, from: date)
        let weekdayLetter = weekdaySymbols[weekday - 1]

        // Check if there's a completed workout for this day
        let workoutLetter = getWorkoutLetter(for: date)

        return DayInfo(
            date: date,
            day: day,
            weekdayLetter: weekdayLetter,
            isToday: isToday,
            isCurrentMonth: isCurrentMonth,
            workoutLetter: workoutLetter
        )
    }

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
        LinearGradient(
            colors: [Color(hex: "#3D2A1A"), Color(hex: "#1A1410")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        WeeklyCalendarView(userProgram: workoutProgram)
            .padding()
    }
}
