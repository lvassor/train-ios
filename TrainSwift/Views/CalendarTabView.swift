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

struct CalendarStatsData {
    let workoutsThisMonth: Int
    let trainingTimeThisMonth: Int           // total seconds
    let totalVolumeThisMonth: Double         // sum of weight × reps
    let dailyVolumeData: [(Date, Double)]    // cumulative volume per day for line chart
    let pbsThisMonth: Int
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

                            }
                            .frame(height: 44)
                        }
                    }
                    .padding(Spacing.md)
                    .appCard()

                    // Stats grid — equal h/v spacing for clean cross layout
                    if let stats = statsData {
                        let gridSpacing: CGFloat = Spacing.md
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: gridSpacing), GridItem(.flexible(), spacing: gridSpacing)],
                            spacing: gridSpacing
                        ) {
                            WorkoutsThisMonthCard(count: stats.workoutsThisMonth)
                            TotalVolumeCard(totalVolume: stats.totalVolumeThisMonth, dailyData: stats.dailyVolumeData)
                            TrainingTimeCard(totalSeconds: stats.trainingTimeThisMonth)
                            NavigationLink(destination: MilestonesView()) {
                                PBsThisMonthCard(count: stats.pbsThisMonth)
                            }
                            .buttonStyle(.plain)
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
            loadStatsData()
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

        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let monthEnd: Date
        if calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month) {
            // Current month: only up to tomorrow
            monthEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        } else {
            // Past month: full month
            monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        }

        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND completedAt >= %@ AND completedAt < %@",
            userId as CVarArg,
            monthStart as NSDate,
            monthEnd as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: true)]

        var sessions: [CDWorkoutSession] = []
        do {
            sessions = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
        } catch {
            AppLogger.logDatabase("Failed to fetch stats sessions: \(error)", level: .error)
            return
        }

        // 1. Workouts this month
        let workoutsCount = sessions.count

        // 2. Total training time
        let totalSeconds = sessions.reduce(0) { $0 + Int($1.durationSeconds) }

        // 3. Total volume + cumulative daily volume for line chart
        var dailyVolumes: [Date: Double] = [:]
        var totalVolume: Double = 0
        for session in sessions {
            let dayKey = calendar.startOfDay(for: session.completedAt ?? Date())
            let exercises = session.getLoggedExercises()
            let sessionVolume = exercises.flatMap { $0.sets.filter(\.completed) }
                .reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            dailyVolumes[dayKey, default: 0] += sessionVolume
            totalVolume += sessionVolume
        }

        // Build cumulative daily data for the line chart
        let sortedDays = dailyVolumes.keys.sorted()
        var cumulative = 0.0
        var cumulativeData: [(Date, Double)] = []
        for day in sortedDays {
            cumulative += dailyVolumes[day] ?? 0
            cumulativeData.append((day, cumulative))
        }

        // 4. PBs this month
        let milestoneService = MilestoneService()
        let allPBs = milestoneService.computeRecentPBs()
        let monthPBCount = allPBs.filter { pb in
            calendar.isDate(pb.date, equalTo: monthStart, toGranularity: .month)
        }.count

        statsData = CalendarStatsData(
            workoutsThisMonth: workoutsCount,
            trainingTimeThisMonth: totalSeconds,
            totalVolumeThisMonth: totalVolume,
            dailyVolumeData: cumulativeData,
            pbsThisMonth: monthPBCount
        )
        statsLoaded = true
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

// MARK: - Stat Cards

// MARK: - Workouts This Month Card

struct WorkoutsThisMonthCard: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Workouts")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)

            Text("\(count)")
                .font(.trainSmallNumber)
                .foregroundColor(.trainPrimary)

            Text("this month")
                .font(.trainCaptionSmall)
                .foregroundColor(.trainTextMuted)

            Spacer()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .appCard()
    }
}

// MARK: - Training Time Card

struct TrainingTimeCard: View {
    let totalSeconds: Int

    private var formattedTime: String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(minutes)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Training Time")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)

            Text(formattedTime)
                .font(.trainSmallNumber)
                .foregroundColor(.trainPrimary)

            Text("this month")
                .font(.trainCaptionSmall)
                .foregroundColor(.trainTextMuted)

            Spacer()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .appCard()
    }
}

// MARK: - Total Volume Card

struct TotalVolumeCard: View {
    let totalVolume: Double
    let dailyData: [(Date, Double)]

    private var formattedVolume: String {
        if totalVolume >= 1000 {
            let thousands = totalVolume / 1000
            return String(format: "%.1fk", thousands)
        }
        return "\(Int(totalVolume))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Total Volume")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)

            Text("\(formattedVolume) kg")
                .font(.trainSmallNumber)
                .foregroundColor(.trainPrimary)

            if dailyData.count >= 2 {
                Chart {
                    ForEach(dailyData, id: \.0) { date, volume in
                        LineMark(
                            x: .value("Day", date),
                            y: .value("Volume", volume)
                        )
                        .foregroundStyle(Color.trainPrimary)
                        .interpolationMethod(.monotone)

                        AreaMark(
                            x: .value("Day", date),
                            y: .value("Volume", volume)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.trainPrimary.opacity(0.3), Color.trainPrimary.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 40)
            }

            Text("this month")
                .font(.trainCaptionSmall)
                .foregroundColor(.trainTextMuted)

            Spacer()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .appCard()
    }
}

// MARK: - PBs This Month Card

struct PBsThisMonthCard: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("PBs Achieved")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)

            HStack(spacing: Spacing.sm) {
                Text("\(count)")
                    .font(.trainSmallNumber)
                    .foregroundColor(.trainPrimary)
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(.trainPrimary)
            }

            Text("this month")
                .font(.trainCaptionSmall)
                .foregroundColor(.trainTextMuted)

            Spacer()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .appCard()
        .shimmerEffect()
    }
}
