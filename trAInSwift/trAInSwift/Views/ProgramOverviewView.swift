//
//  ProgramOverviewView.swift
//  trAInSwift
//
//  Shows all weeks and sessions in the user's program
//

import SwiftUI

struct ProgramOverviewView: View {
    @ObservedObject var authService = AuthService.shared
    let userProgram: UserProgram

    @State private var selectedSession: SelectedSessionInfo?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Your Program")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text(userProgram.program.type.description)
                        .font(.trainHeadline)
                        .foregroundColor(.trainTextSecondary)

                    Text("\(userProgram.program.totalWeeks) weeks • \(userProgram.program.daysPerWeek) days/week")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                // Weeks
                ForEach(1...userProgram.program.totalWeeks, id: \.self) { week in
                    WeekSection(
                        weekNumber: week,
                        userProgram: userProgram,
                        onSessionTap: { sessionIndex in
                            selectedSession = SelectedSessionInfo(
                                weekNumber: week,
                                sessionIndex: sessionIndex
                            )
                        }
                    )
                    .padding(.horizontal, Spacing.lg)
                }

                Spacer()
                    .frame(height: 40)
            }
        }
        .background(Color.trainBackground.ignoresSafeArea())
        .navigationTitle("Program")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedSession) { info in
            SessionDetailView(
                userProgram: userProgram,
                weekNumber: info.weekNumber,
                sessionIndex: info.sessionIndex
            )
        }
    }
}

// MARK: - Week Section

struct WeekSection: View {
    let weekNumber: Int
    let userProgram: UserProgram
    let onSessionTap: (Int) -> Void

    var isCurrentWeek: Bool {
        weekNumber == userProgram.currentWeek
    }

    var isFutureWeek: Bool {
        weekNumber > userProgram.currentWeek
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Week Header
            HStack {
                Text("Week \(weekNumber)")
                    .font(.trainHeadline)
                    .foregroundColor(isFutureWeek ? .trainTextSecondary : .trainTextPrimary)

                if isCurrentWeek {
                    Text("CURRENT")
                        .font(.trainCaption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.trainPrimary)
                        .cornerRadius(CornerRadius.sm)
                }

                Spacer()
            }

            // Sessions
            VStack(spacing: Spacing.sm) {
                ForEach(Array(userProgram.program.sessions.enumerated()), id: \.element.id) { index, session in
                    SessionRow(
                        session: session,
                        sessionIndex: index,
                        weekNumber: weekNumber,
                        userProgram: userProgram,
                        onTap: { onSessionTap(index) }
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .opacity(isFutureWeek ? 0.6 : 1.0)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ProgramSession
    let sessionIndex: Int
    let weekNumber: Int
    let userProgram: UserProgram
    let onTap: () -> Void

    var sessionId: String {
        "week\(weekNumber)-session\(sessionIndex)"
    }

    var isCompleted: Bool {
        userProgram.completedSessions.contains(sessionId)
    }

    var isNextSession: Bool {
        weekNumber == userProgram.currentWeek && sessionIndex == userProgram.currentSessionIndex && !isCompleted
    }

    var isFuture: Bool {
        weekNumber > userProgram.currentWeek ||
        (weekNumber == userProgram.currentWeek && sessionIndex > userProgram.currentSessionIndex)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Completion indicator
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Color.trainPrimary : Color.trainBorder, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.trainPrimary)
                    }
                }

                // Session info
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.dayName)
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    Text("\(session.exercises.count) exercises")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()

                // Next badge or chevron
                if isNextSession {
                    Text("NEXT")
                        .font(.trainCaption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.trainPrimary)
                        .cornerRadius(CornerRadius.sm)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.trainTextSecondary)
                }
            }
            .padding(Spacing.md)
            .background(isNextSession ? Color.trainPrimary.opacity(0.05) : Color.trainBackground)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(isNextSession ? Color.trainPrimary : Color.clear, lineWidth: 2)
            )
        }
        .disabled(isFuture)
        .opacity(isFuture ? 0.5 : 1.0)
    }
}

// MARK: - Supporting Types

struct SelectedSessionInfo: Identifiable, Hashable {
    let id = UUID()
    let weekNumber: Int
    let sessionIndex: Int
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProgramOverviewView(
            userProgram: UserProgram(
                program: Program(
                    type: .pushPullLegs,
                    daysPerWeek: 3,
                    sessionDuration: .medium,
                    sessions: [
                        ProgramSession(dayName: "Push", exercises: []),
                        ProgramSession(dayName: "Pull", exercises: []),
                        ProgramSession(dayName: "Legs", exercises: [])
                    ],
                    totalWeeks: 8
                )
            )
        )
    }
}
