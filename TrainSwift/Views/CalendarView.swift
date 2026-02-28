//
//  CalendarView.swift
//  TrainSwift
//
//  Calendar view showing workout history
//

import SwiftUI
import CoreData

struct CalendarView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var authService = AuthService.shared
    @State private var selectedDate: Date?
    @State private var currentMonth: Date = Date()

    // Fetch all workout sessions for current user
    @FetchRequest private var workoutSessions: FetchedResults<CDWorkoutSession>

    init() {
        // Filter to current user's sessions only
        let request: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWorkoutSession.completedAt, ascending: false)]
        if let userId = AuthService.shared.currentUser?.id {
            request.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        } else {
            request.predicate = NSPredicate(value: false) // No user — show nothing
        }
        _workoutSessions = FetchRequest(fetchRequest: request)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                    // Month Navigation
                    MonthNavigationView(currentMonth: $currentMonth)
                        .glassCardPadding()
                        .glassCompactCard()

                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Calendar Grid
                            CalendarGridView(
                                currentMonth: currentMonth,
                                workouts: convertToWorkoutSessions(Array(workoutSessions)),
                                selectedDate: $selectedDate
                            )
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)

                            // Selected Date Workouts
                            if let selected = selectedDate {
                                WorkoutsForDateView(
                                    date: selected,
                                    workouts: getWorkouts(for: selected)
                                )
                                .padding(.horizontal, Spacing.lg)
                            }

                            Spacer()
                                .frame(height: ElementHeight.tabSelector)
                        }
                    }
                }
            .charcoalGradientBackground()
            .scrollContentBackground(.hidden)
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .foregroundColor(.trainPrimary)
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Close workout history")
                }
            }
        }
    }

    private func getWorkouts(for date: Date) -> [WorkoutSession] {
        let calendar = Calendar.current
        let filtered = workoutSessions.filter { session in
            guard let completedAt = session.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: date)
        }
        return convertToWorkoutSessions(Array(filtered))
    }

    private func convertToWorkoutSessions(_ cdSessions: [CDWorkoutSession]) -> [WorkoutSession] {
        return cdSessions.compactMap { cdSession in
            guard let id = cdSession.id,
                  let userId = cdSession.userId,
                  let completedAt = cdSession.completedAt,
                  let sessionName = cdSession.sessionName else {
                return nil
            }

            let loggedExercises = cdSession.getLoggedExercises()

            return WorkoutSession(
                id: id.uuidString,
                userId: userId.uuidString,
                date: completedAt,
                sessionType: sessionName,
                weekNumber: Int(cdSession.weekNumber),
                exercises: loggedExercises,
                durationMinutes: cdSession.durationMinutes,
                completed: true
            )
        }
    }
}

// MARK: - Month Navigation

struct MonthNavigationView: View {
    @Binding var currentMonth: Date

    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.trainPrimary)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(monthYearString)
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.trainPrimary)
            }
            .accessibilityLabel("Next month")
        }
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    // Swipe left = next month, Swipe right = previous month
                    if value.translation.width > 50 {
                        // Swiped right - go to previous month
                        previousMonth()
                    } else if value.translation.width < -50 {
                        // Swiped left - go to next month
                        nextMonth()
                    }
                }
        )
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - Calendar Grid

struct CalendarGridView: View {
    let currentMonth: Date
    let workouts: [WorkoutSession]
    @Binding var selectedDate: Date?

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Day Headers
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar Days
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            hasWorkout: hasWorkout(on: date),
                            isSelected: isSelected(date),
                            isToday: isToday(date),
                            onTap: { selectedDate = date }
                        )
                    } else {
                        // Empty cell for alignment
                        Color.clear
                            .frame(height: ElementHeight.tabSelector)
                    }
                }
            }
        }
        .glassCompactPadding()
        .appCard()
    }

    private func getDaysInMonth() -> [Date?] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var currentDate = monthFirstWeek.start

        while days.count < 42 { // 6 weeks max
            if calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }

            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }

        return days
    }

    private func hasWorkout(on date: Date) -> Bool {
        let calendar = Calendar.current
        return workouts.contains { workout in
            calendar.isDate(workout.date, inSameDayAs: date)
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selected)
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayView: View {
    let date: Date
    let hasWorkout: Bool
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                if isSelected {
                    Circle()
                        .fill(Color.trainPrimary)
                        .accentGlow()
                } else if isToday {
                    Circle()
                        .stroke(Color.trainPrimary, lineWidth: 2)
                }

                // Day Number
                Text("\(dayNumber)")
                    .font(.trainBody)
                    .foregroundColor(isSelected ? .white : .trainTextPrimary)

                // Workout Indicator
                if hasWorkout && !isSelected {
                    Circle()
                        .fill(Color.trainPrimary)
                        .frame(width: 4, height: 4)
                        .offset(y: 12)
                }
            }
            .frame(height: ElementHeight.tabSelector)
        }
        .accessibilityLabel("Day \(dayNumber)")
        .accessibilityValue(hasWorkout ? "Has workout" : "No workout")
    }
}

// MARK: - Workouts for Selected Date

struct WorkoutsForDateView: View {
    let date: Date
    let workouts: [WorkoutSession]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(formatDate(date))
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            if workouts.isEmpty {
                Text("No workouts on this day")
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
                    .padding(.vertical, Spacing.lg)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(workouts) { workout in
                        WorkoutHistoryCard(workout: workout)
                    }
                }
            }
        }
        .glassCompactPadding()
        .appCard()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

struct WorkoutHistoryCard: View {
    let workout: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(workout.sessionType)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)

                Spacer()

                Text("\(workout.durationMinutes) min")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
            }

            HStack(spacing: Spacing.lg) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "list.bullet")
                        .font(.caption)
                    Text("\(workout.exercises.count) exercises")
                        .font(.trainCaption)
                }
                .foregroundColor(.trainTextSecondary)

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                    Text("\(workout.completedSets) sets")
                        .font(.trainCaption)
                }
                .foregroundColor(.trainTextSecondary)
            }
        }
        .padding(Spacing.md)
        .glassCompactCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.sessionType), \(workout.durationMinutes) minutes, \(workout.exercises.count) exercises")
    }
}

#Preview {
    CalendarView()
}
