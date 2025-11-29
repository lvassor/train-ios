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
    private let mutedCircleFill = Color(hex: "#4A4540").opacity(0.45)

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("THIS WEEK")
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .tracking(1.5)
                    .foregroundColor(warmSecondaryText)

                Spacer()

                Text("Let's start your journey")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)

            // Week row (always visible)
            weekRow
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            // Expanded month view
            if isExpanded {
                monthView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }

            // Expand/collapse button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(warmSecondaryText)
                    .frame(height: 24)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 8)
        }
        .warmGlassCard(cornerRadius: 20)
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

    // MARK: - Month View

    private var monthView: some View {
        let monthData = getMonthData()

        return VStack(spacing: 16) {
            // Month/Year header
            Text(monthYearString)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Calendar grid
            VStack(spacing: 8) {
                // Day headers (S M T W T F S)
                HStack(spacing: 0) {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { letter in
                        Text(letter)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(warmSecondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Week rows
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
