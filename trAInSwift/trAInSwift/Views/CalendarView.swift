//
//  CalendarView.swift
//  trAInApp
//
//  Calendar view showing workout history
//

import SwiftUI

struct CalendarView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared
    @State private var selectedDate: Date?
    @State private var currentMonth: Date = Date()

    var body: some View {
        NavigationView {
            ZStack {
                Color.trainBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Month Navigation
                    MonthNavigationView(currentMonth: $currentMonth)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background(Color.white)

                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Calendar Grid
                            CalendarGridView(
                                currentMonth: currentMonth,
                                workouts: [], // TODO: Implement workout history from Core Data
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
                                .frame(height: 40)
                        }
                    }
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .foregroundColor(.trainPrimary)
                    }
                }
            }
        }
    }

    private func getWorkouts(for date: Date) -> [WorkoutSession] {
        // TODO: Implement filtering from Core Data WorkoutSessions
        return []
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
        }
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
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
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

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                if isSelected {
                    Circle()
                        .fill(Color.trainPrimary)
                } else if isToday {
                    Circle()
                        .stroke(Color.trainPrimary, lineWidth: 2)
                }

                // Day Number
                Text("\(Calendar.current.component(.day, from: date))")
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
            .frame(height: 40)
        }
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
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
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
        .padding(Spacing.sm)
        .background(Color.trainBackground)
        .cornerRadius(CornerRadius.sm)
    }
}

#Preview {
    CalendarView()
}
