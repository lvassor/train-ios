//
//  HomeView.swift
//  trAInApp
//
//  Main home screen showing program overview and navigation
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var showCalendar = false
    @State private var showProfile = false
    @State private var showWorkout = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.trainBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Welcome back,")
                                    .font(.trainSubtitle)
                                    .foregroundColor(.trainTextSecondary)

                                Text(getUserFirstName())
                                    .font(.trainTitle)
                                    .foregroundColor(.trainTextPrimary)
                            }

                            Spacer()

                            Button(action: { showProfile = true }) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.trainPrimary)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)

                        if let userProgram = authService.currentUser?.currentProgram {
                            // Current Program Card
                            CurrentProgramCard(userProgram: userProgram, onStartWorkout: {
                                showWorkout = true
                            })
                            .padding(.horizontal, Spacing.lg)

                            // Quick Stats
                            QuickStatsView(userProgram: userProgram)
                                .padding(.horizontal, Spacing.lg)

                            // Action Buttons
                            VStack(spacing: Spacing.md) {
                                Button(action: { showCalendar = true }) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.title3)
                                        Text("View Calendar")
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

                                NavigationLink(destination: ProgramDetailView()) {
                                    HStack {
                                        Image(systemName: "list.bullet")
                                            .font(.title3)
                                        Text("View Full Program")
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
                            .padding(.horizontal, Spacing.lg)
                        } else {
                            // No program yet - show prompt to take questionnaire
                            NoProgramView()
                                .padding(.horizontal, Spacing.lg)
                        }

                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showCalendar) {
            CalendarView()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .fullScreenCover(isPresented: $showWorkout) {
            if let userProgram = authService.currentUser?.currentProgram,
               userProgram.currentSessionIndex < userProgram.program.sessions.count {
                let session = userProgram.program.sessions[userProgram.currentSessionIndex]
                WorkoutLoggerView(
                    session: session,
                    weekNumber: userProgram.currentWeek,
                    onComplete: {
                        showWorkout = false
                    }
                )
            }
        }
    }

    private func getUserFirstName() -> String {
        guard let email = authService.currentUser?.email else { return "User" }
        return email.components(separatedBy: "@").first?.capitalized ?? "User"
    }
}

// MARK: - Current Program Card

struct CurrentProgramCard: View {
    let userProgram: UserProgram
    let onStartWorkout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Current Program")
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

            Button(action: onStartWorkout) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Workout")
                        .font(.trainBodyMedium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: ButtonHeight.standard)
                .background(Color.trainPrimary)
                .cornerRadius(CornerRadius.md)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Quick Stats

struct QuickStatsView: View {
    let userProgram: UserProgram

    var body: some View {
        HStack(spacing: Spacing.md) {
            StatCard(
                title: "Workouts",
                value: "\(userProgram.totalWorkoutsCompleted)",
                icon: "flame.fill"
            )

            StatCard(
                title: "This Week",
                value: "\(getThisWeekCount())/\(userProgram.program.daysPerWeek)",
                icon: "calendar"
            )

            StatCard(
                title: "Streak",
                value: "\(calculateStreak())",
                icon: "bolt.fill"
            )
        }
    }

    private func getThisWeekCount() -> Int {
        let currentWeekSessions = userProgram.completedSessions.filter { sessionId in
            sessionId.hasPrefix("week\(userProgram.currentWeek)-")
        }
        return currentWeekSessions.count
    }

    private func calculateStreak() -> Int {
        // Simplified streak calculation for MVP
        return min(userProgram.totalWorkoutsCompleted, 7)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.trainPrimary)

            Text(value)
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            Text(title)
                .font(.trainCaption)
                .foregroundColor(.trainTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - No Program View

struct NoProgramView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.trainPrimary)

            VStack(spacing: Spacing.sm) {
                Text("No Active Program")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Complete the questionnaire to get your personalized training program")
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                // This would navigate to questionnaire
            }) {
                Text("Take Questionnaire")
                    .font(.trainBodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: ButtonHeight.standard)
                    .background(Color.trainPrimary)
                    .cornerRadius(CornerRadius.md)
            }
        }
        .padding(Spacing.xl)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    HomeView()
}
