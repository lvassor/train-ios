//
//  DashboardView.swift
//  trAInSwift
//
//  Main dashboard showing user's program and progress
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var showProgramOverview = false
    @State private var showCalendar = false
    @State private var showProfile = false

    var user: User? {
        authService.currentUser
    }

    var userProgram: UserProgram? {
        user?.currentProgram
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Welcome back,")
                            .font(.trainSubtitle)
                            .foregroundColor(.trainTextSecondary)

                        Text(getUserFirstName())
                            .font(.trainTitle)
                            .foregroundColor(.trainTextPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                    if let program = userProgram {
                        // Your Program Card
                        Button(action: { showProgramOverview = true }) {
                            ProgramCard(userProgram: program)
                        }
                        .padding(.horizontal, Spacing.lg)

                        // Quick Stats
                        QuickStatsCard(userProgram: program)
                            .padding(.horizontal, Spacing.lg)

                        // Action Buttons
                        VStack(spacing: Spacing.md) {
                            ActionButton(
                                icon: "calendar",
                                title: "View Full Program",
                                action: { showProgramOverview = true }
                            )

                            ActionButton(
                                icon: "chart.bar.fill",
                                title: "Workout History",
                                action: { showCalendar = true }
                            )

                            ActionButton(
                                icon: "person.circle",
                                title: "Profile & Settings",
                                action: { showProfile = true }
                            )
                        }
                        .padding(.horizontal, Spacing.lg)
                    }

                    Spacer()
                }
            }
            .background(Color.trainBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $showProgramOverview) {
                if let program = userProgram {
                    ProgramOverviewView(userProgram: program)
                }
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }

    private func getUserFirstName() -> String {
        guard let email = user?.email else { return "User" }
        return email.components(separatedBy: "@").first?.capitalized ?? "User"
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    let userProgram: UserProgram

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Your Program")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)

                    Text(userProgram.program.type.description)
                        .font(.trainHeadline)
                        .foregroundColor(.trainTextPrimary)

                    Text("\(userProgram.program.daysPerWeek) days/week • \(userProgram.program.sessionDuration.rawValue)")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("Week \(userProgram.currentWeek)")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainPrimary)

                    Text("of \(userProgram.program.totalWeeks)")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }
            }

            Divider()

            // Next Session
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Next Session")
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)

                Text(userProgram.nextSessionType)
                    .font(.trainBodyMedium)
                    .foregroundColor(.trainTextPrimary)
            }

            HStack {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.trainPrimary)
                Spacer()
                Text("Tap to view")
                    .font(.trainCaption)
                    .foregroundColor(.trainPrimary)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Quick Stats Card

struct QuickStatsCard: View {
    let userProgram: UserProgram

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("Quick Stats")
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Spacing.md) {
                StatPill(
                    icon: "flame.fill",
                    value: "\(userProgram.totalWorkoutsCompleted)",
                    label: "Workouts"
                )

                StatPill(
                    icon: "calendar",
                    value: "\(getThisWeekCount())/\(userProgram.program.daysPerWeek)",
                    label: "This Week"
                )

                StatPill(
                    icon: "bolt.fill",
                    value: "\(min(userProgram.totalWorkoutsCompleted, 7))",
                    label: "Streak"
                )
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func getThisWeekCount() -> Int {
        let currentWeekSessions = userProgram.completedSessions.filter { sessionId in
            sessionId.hasPrefix("week\(userProgram.currentWeek)-")
        }
        return currentWeekSessions.count
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.trainPrimary)

            Text(value)
                .font(.trainBodyMedium)
                .foregroundColor(.trainTextPrimary)

            Text(label)
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color.trainBackground)
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.trainBodyMedium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.trainTextPrimary)
            .padding(Spacing.md)
            .background(Color.white)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
