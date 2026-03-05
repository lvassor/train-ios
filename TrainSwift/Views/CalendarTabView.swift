//
//  CalendarTabView.swift
//  TrainSwift
//
//  Full-month calendar with weekly completion tracking and session navigation
//

import SwiftUI
import CoreData
import Charts

// MARK: - Data Models

struct WeekStatPoint: Identifiable {
    let id = UUID()
    let weekLabel: String
    let value: Double
}

struct CalendarStatsData {
    let weeklyVolume: [WeekStatPoint]
    let consistency: [WeekStatPoint]
    let avgDuration: [WeekStatPoint]
    let currentStreak: Int
    let longestStreak: Int
    let targetDaysPerWeek: Int
}

struct CalendarDayData: Identifiable {
    let id = UUID()
    let date: Date
    let day: Int
    let isToday: Bool
    let isCurrentMonth: Bool
    let sessions: [CDWorkoutSession]

    var hasSessions: Bool { !sessions.isEmpty }
    var hasMultipleSessions: Bool { sessions.count > 1 }

    var displayText: String? {
        guard hasSessions else { return nil }
        if sessions.count == 1, let name = sessions.first?.sessionName {
            return SessionNameFormatter.abbreviation(for: name)
        }
        return nil // multi-session: caller renders "+" icon
    }
}

struct CalendarWeekData: Identifiable {
    let id = UUID()
    let days: [CalendarDayData]
    let completedCount: Int
}

// MARK: - CalendarTabView

struct CalendarTabView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var currentMonth: Date = Date()
    @State private var weeks: [CalendarWeekData] = []
    @State private var selectedDate: Date? = nil
    @State private var sessionsByDay: [Date: [CDWorkoutSession]] = [:]
    @State private var statsData: CalendarStatsData? = nil
    @State private var statsLoaded: Bool = false

    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday start
        return cal
    }()

    private var userProgram: WorkoutProgram? {
        authService.getCurrentProgram()
    }

    private var daysPerWeek: Int {
        Int(userProgram?.daysPerWeek ?? 0)
    }

    private let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        ZStack {
            AppGradient.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Month navigation
                    monthNavigationHeader
                        .padding(.top, Spacing.md)

                    // Calendar grid
                    VStack(spacing: Spacing.sm) {
                        // Weekday header row
                        weekdayHeaderRow

                        // Week rows
                        ForEach(weeks) { week in
                            HStack(spacing: 0) {
                                ForEach(week.days) { day in
                                    CalendarDayCell(
                                        day: day,
                                        isSelected: isDateSelected(day.date),
                                        onTap: {
                                            if day.hasSessions {
                                                selectedDate = day.date
                                            }
                                        }
                                    )
                                    .frame(maxWidth: .infinity)
                                }

                                // Weekly completion badge
                                if daysPerWeek > 0 {
                                    WeeklyCompletionBadge(
                                        completed: week.completedCount,
                                        target: daysPerWeek
                                    )
                                    .frame(width: 36)
                                }
                            }
                            .frame(height: 44)
                        }
                    }
                    .padding(Spacing.md)
                    .appCard()

                    // Stats grid
                    if let stats = statsData {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: Spacing.md
                        ) {
                            VolumeStatCard(data: stats.weeklyVolume)
                            ConsistencyStatCard(data: stats.consistency, target: stats.targetDaysPerWeek)
                            DurationStatCard(data: stats.avgDuration)
                            StreakStatCard(currentStreak: stats.currentStreak, longestStreak: stats.longestStreak)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedDate) { date in
            let daySessions = sessionsForDay(date)
            if let program = userProgram {
                CalendarSessionDetailView(
                    sessions: daySessions,
                    userProgram: program
                )
            }
        }
        .onAppear {
            reloadMonth()
            if !statsLoaded {
                loadStatsData()
            }
        }
        .onChange(of: currentMonth) { _, _ in
            reloadMonth()
        }
    }

    // MARK: - Month Navigation

    private var monthNavigationHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: IconSize.sm, weight: .semibold))
                    .foregroundColor(.trainPrimary)
                    .frame(width: ElementHeight.touchTarget, height: ElementHeight.touchTarget)
            }

            Spacer()

            Text(monthYearString)
                .font(.trainBodyMedium)
                .foregroundColor(.trainTextPrimary)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: IconSize.sm, weight: .semibold))
                    .foregroundColor(canGoForward ? .trainPrimary : .trainTextSecondary.opacity(0.3))
                    .frame(width: ElementHeight.touchTarget, height: ElementHeight.touchTarget)
            }
            .disabled(!canGoForward)
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdayLetters, id: \.self) { letter in
                Text(letter)
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
                    .frame(maxWidth: .infinity)
            }

            // Empty space for completion column
            if daysPerWeek > 0 {
                Color.clear
                    .frame(width: 36)
            }
        }
    }

    // MARK: - Data Fetching

    private func reloadMonth() {
        let gridRange = visibleGridRange(for: currentMonth)
        sessionsByDay = batchFetchSessionsGrouped(from: gridRange.start, to: gridRange.end)
        weeks = generateMonthGrid(for: currentMonth)
    }

    private func visibleGridRange(for month: Date) -> (start: Date, end: Date) {
        let components = calendar.dateComponents([.year, .month], from: month)
        let firstOfMonth = calendar.date(from: components)!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToSubtract = (firstWeekday == 1) ? 6 : firstWeekday - 2
        let gridStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstOfMonth)!
        let gridEnd = calendar.date(byAdding: .day, value: 42, to: gridStart)!
        return (gridStart, gridEnd)
    }

    private func batchFetchSessionsGrouped(from startDate: Date, to endDate: Date) -> [Date: [CDWorkoutSession]] {
        guard let userId = authService.currentUser?.id else { return [:] }

        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND completedAt >= %@ AND completedAt < %@",
            userId as CVarArg,
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: true)]

        var grouped: [Date: [CDWorkoutSession]] = [:]
        do {
            let sessions = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            for session in sessions {
                guard let completedAt = session.completedAt else { continue }
                let dayKey = calendar.startOfDay(for: completedAt)
                grouped[dayKey, default: []].append(session)
            }
        } catch {
            AppLogger.logDatabase("Failed to batch-fetch sessions: \(error)", level: .error)
        }

        return grouped
    }

    // MARK: - Stats Data Loading

    private func loadStatsData() {
        guard let userId = authService.currentUser?.id else { return }

        let today = calendar.startOfDay(for: Date())
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (currentWeekday == 1) ? 6 : currentWeekday - 2
        let currentWeekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!
        let sixWeeksAgoStart = calendar.date(byAdding: .weekOfYear, value: -5, to: currentWeekStart)!
        let currentWeekEnd = calendar.date(byAdding: .day, value: 7, to: currentWeekStart)!

        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND completedAt >= %@ AND completedAt < %@",
            userId as CVarArg,
            sixWeeksAgoStart as NSDate,
            currentWeekEnd as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: true)]

        var sessions: [CDWorkoutSession] = []
        do {
            sessions = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
        } catch {
            AppLogger.logDatabase("Failed to fetch stats sessions: \(error)", level: .error)
            return
        }

        // Group sessions into 6 weekly buckets
        var weekBuckets: [(start: Date, sessions: [CDWorkoutSession])] = []
        for weekOffset in 0..<6 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: sixWeeksAgoStart)!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            let weekSessions = sessions.filter { session in
                guard let date = session.completedAt else { return false }
                return date >= weekStart && date < weekEnd
            }
            weekBuckets.append((start: weekStart, sessions: weekSessions))
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM"

        var volumePoints: [WeekStatPoint] = []
        var consistencyPoints: [WeekStatPoint] = []
        var durationPoints: [WeekStatPoint] = []

        for bucket in weekBuckets {
            let label = dateFormatter.string(from: bucket.start)

            // Volume: sum(weight × reps) for completed sets
            var weekVolume: Double = 0
            for session in bucket.sessions {
                let exercises = session.getLoggedExercises()
                for exercise in exercises {
                    for set in exercise.sets where set.completed {
                        weekVolume += set.weight * Double(set.reps)
                    }
                }
            }
            volumePoints.append(WeekStatPoint(weekLabel: label, value: weekVolume))

            // Consistency: session count
            consistencyPoints.append(WeekStatPoint(weekLabel: label, value: Double(bucket.sessions.count)))

            // Duration: avg minutes
            let totalMinutes = bucket.sessions.reduce(0) { $0 + Int($1.durationSeconds) / 60 }
            let avgMinutes = bucket.sessions.isEmpty ? 0.0 : Double(totalMinutes) / Double(bucket.sessions.count)
            durationPoints.append(WeekStatPoint(weekLabel: label, value: avgMinutes))
        }

        let streak = SessionCompletionHelper.calculateStreak(userId: userId)
        let longest = calculateLongestStreak(userId: userId)

        statsData = CalendarStatsData(
            weeklyVolume: volumePoints,
            consistency: consistencyPoints,
            avgDuration: durationPoints,
            currentStreak: streak,
            longestStreak: longest,
            targetDaysPerWeek: daysPerWeek
        )
        statsLoaded = true
    }

    private func calculateLongestStreak(userId: UUID) -> Int {
        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: true)]

        do {
            let sessions = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            var uniqueDays: [Date] = []
            for session in sessions {
                guard let date = session.completedAt else { continue }
                let dayStart = calendar.startOfDay(for: date)
                if uniqueDays.last != dayStart {
                    uniqueDays.append(dayStart)
                }
            }

            guard !uniqueDays.isEmpty else { return 0 }

            var longest = 1
            var current = 1
            for i in 1..<uniqueDays.count {
                let diff = calendar.dateComponents([.day], from: uniqueDays[i - 1], to: uniqueDays[i]).day ?? 0
                if diff == 1 {
                    current += 1
                    longest = max(longest, current)
                } else {
                    current = 1
                }
            }
            return longest
        } catch {
            return 0
        }
    }

    // MARK: - Month Grid Generation

    private func generateMonthGrid(for month: Date) -> [CalendarWeekData] {
        let components = calendar.dateComponents([.year, .month], from: month)
        let firstOfMonth = calendar.date(from: components)!
        let currentMonthComponent = calendar.component(.month, from: month)

        let gridRange = visibleGridRange(for: month)
        var currentDay = gridRange.start
        var result: [CalendarWeekData] = []

        for _ in 0..<6 {
            var days: [CalendarDayData] = []
            var weekSessionCount = 0

            for _ in 0..<7 {
                let dayKey = calendar.startOfDay(for: currentDay)
                let daySessions = sessionsByDay[dayKey] ?? []
                weekSessionCount += daySessions.count

                days.append(CalendarDayData(
                    date: currentDay,
                    day: calendar.component(.day, from: currentDay),
                    isToday: calendar.isDateInToday(currentDay),
                    isCurrentMonth: calendar.component(.month, from: currentDay) == currentMonthComponent,
                    sessions: daySessions
                ))
                currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
            }

            result.append(CalendarWeekData(
                days: days,
                completedCount: weekSessionCount
            ))

            // Stop if all remaining days would be outside current month and we have enough rows
            let nextDayMonth = calendar.component(.month, from: currentDay)
            if nextDayMonth != currentMonthComponent && result.count >= 4 {
                // Check if the next full week is entirely outside the current month
                let daysLeftInGrid = (0..<7).allSatisfy { offset in
                    let d = calendar.date(byAdding: .day, value: offset, to: currentDay)!
                    return calendar.component(.month, from: d) != currentMonthComponent
                }
                if daysLeftInGrid { break }
            }
        }

        return result
    }

    // MARK: - Helpers

    private func sessionsForDay(_ date: Date) -> [CDWorkoutSession] {
        let dayKey = calendar.startOfDay(for: date)
        return sessionsByDay[dayKey] ?? []
    }

    private func isDateSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var canGoForward: Bool {
        let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let nowComponents = calendar.dateComponents([.year, .month], from: Date())
        if currentComponents.year! < nowComponents.year! { return true }
        if currentComponents.year! == nowComponents.year! && currentComponents.month! < nowComponents.month! { return true }
        return false
    }

    private func previousMonth() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        }
    }

    private func nextMonth() {
        guard canGoForward else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let day: CalendarDayData
    let isSelected: Bool
    let onTap: () -> Void

    private let circleSize: CGFloat = 32

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle
                if day.hasSessions {
                    Circle()
                        .fill(Color.trainPrimary)
                        .frame(width: circleSize, height: circleSize)
                } else if day.isToday {
                    Circle()
                        .stroke(Color.trainPrimary, lineWidth: 2)
                        .frame(width: circleSize, height: circleSize)
                } else {
                    Circle()
                        .fill(Color.trainGradientEdge.opacity(0.8))
                        .frame(width: circleSize, height: circleSize)
                }

                // Content
                if day.hasMultipleSessions {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                } else if let text = day.displayText {
                    Text(text)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(day.day)")
                        .font(.system(size: 13, weight: day.isToday ? .bold : .medium))
                        .foregroundColor(day.isToday ? .trainPrimary : .trainTextSecondary)
                }
            }
            .opacity(day.isCurrentMonth ? 1.0 : 0.3)
        }
        .buttonStyle(.plain)
        .disabled(!day.hasSessions)
    }
}

// MARK: - Weekly Completion Badge

struct WeeklyCompletionBadge: View {
    let completed: Int
    let target: Int

    private var isComplete: Bool { completed >= target }

    var body: some View {
        Text("\(completed)/\(target)")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(isComplete ? .trainPrimary : .trainTextSecondary)
            .frame(width: 32, height: 20)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isComplete
                        ? Color.trainPrimary.opacity(0.15)
                        : Color.white.opacity(0.05))
            )
    }
}

// MARK: - Volume Stat Card

struct VolumeStatCard: View {
    let data: [WeekStatPoint]

    private var latestVolume: String {
        guard let last = data.last, last.value > 0 else { return "--" }
        if last.value >= 1000 {
            return String(format: "%.1fT", last.value / 1000)
        }
        return "\(Int(last.value)) kg"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Weekly Volume")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)

            Text(latestVolume)
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            Chart(Array(data.enumerated()), id: \.element.id) { index, point in
                BarMark(
                    x: .value("Week", point.weekLabel),
                    y: .value("Volume", point.value)
                )
                .foregroundStyle(
                    index == data.count - 1
                        ? Color.trainPrimary
                        : Color.trainTextMuted.opacity(0.3)
                )
                .cornerRadius(CornerRadius.xxs)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 60)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .appCard()
    }
}

// MARK: - Consistency Stat Card

struct ConsistencyStatCard: View {
    let data: [WeekStatPoint]
    let target: Int

    private var latestCount: String {
        guard let last = data.last else { return "--" }
        if target > 0 {
            return "\(Int(last.value))/\(target)"
        }
        return "\(Int(last.value))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Consistency")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)

            Text(latestCount)
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            Chart {
                if target > 0 {
                    RuleMark(y: .value("Target", target))
                        .foregroundStyle(Color.trainPrimary.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }

                ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                    BarMark(
                        x: .value("Week", point.weekLabel),
                        y: .value("Sessions", point.value)
                    )
                    .foregroundStyle(
                        Int(point.value) >= target && target > 0
                            ? Color.trainPrimary
                            : Color.trainTextMuted.opacity(0.3)
                    )
                    .cornerRadius(CornerRadius.xxs)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 60)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .appCard()
    }
}

// MARK: - Duration Stat Card

struct DurationStatCard: View {
    let data: [WeekStatPoint]

    private var latestDuration: String {
        guard let last = data.last, last.value > 0 else { return "--" }
        return "\(Int(last.value)) min"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Avg Duration")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)

            Text(latestDuration)
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            Chart(data) { point in
                AreaMark(
                    x: .value("Week", point.weekLabel),
                    y: .value("Minutes", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.trainPrimary.opacity(0.3),
                            Color.trainPrimary.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Week", point.weekLabel),
                    y: .value("Minutes", point.value)
                )
                .foregroundStyle(Color.trainPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 60)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .appCard()
    }
}

// MARK: - Streak Stat Card

struct StreakStatCard: View {
    let currentStreak: Int
    let longestStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Current Streak")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)

            HStack(spacing: Spacing.sm) {
                if currentStreak > 0 {
                    FlameView(size: 24)
                        .frame(width: 24, height: 24)
                }

                Text("\(currentStreak)")
                    .font(.trainSmallNumber)
                    .foregroundColor(.trainTextPrimary)

                Text(currentStreak == 1 ? "day" : "days")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
            }

            Spacer()

            HStack(spacing: Spacing.xs) {
                Text("Longest:")
                    .font(.trainCaptionSmall)
                    .foregroundColor(.trainTextMuted)
                Text("\(longestStreak)")
                    .font(.trainCaptionSmall)
                    .fontWeight(.medium)
                    .foregroundColor(.trainTextSecondary)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .appCard()
    }
}
