//
//  ProgrammeOverviewView.swift
//  trAInApp
//
//  Created by Claude Code on 2025-10-06.
//

import SwiftUI

struct SessionSelection: Hashable {
    let weekNumber: Int
    let sessionKey: String
}

struct ProgrammeOverviewView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var selectedSession: SessionSelection?

    let totalWeeks = 6

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Programme")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        if let programme = viewModel.currentProgramme {
                            Text(programme.name)
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("6 week 3-day split: Push, Pull, Legs")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Vertical Timeline
                    VStack(spacing: 0) {
                        ForEach(1...totalWeeks, id: \.self) { week in
                            WeekRow(
                                weekNumber: week,
                                currentWeek: viewModel.programmeProgress.currentWeek,
                                programme: viewModel.currentProgramme,
                                viewModel: viewModel,
                                selectedSession: $selectedSession
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationDestination(item: $selectedSession) { selection in
                SessionOverviewView(
                    weekNumber: selection.weekNumber,
                    sessionKey: selection.sessionKey
                )
                .environmentObject(viewModel)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct WeekRow: View {
    let weekNumber: Int
    let currentWeek: Int
    let programme: Programme?
    let viewModel: WorkoutViewModel
    @Binding var selectedSession: SessionSelection?

    var isCurrentWeek: Bool {
        weekNumber == currentWeek
    }

    var isFutureWeek: Bool {
        weekNumber > currentWeek
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Week header
            HStack {
                Text("Week \(weekNumber)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isFutureWeek ? .secondary : .primary)

                if isCurrentWeek {
                    Text("CURRENT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "3C825E"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.top, weekNumber == 1 ? 0 : 24)

            // Sessions for this week
            if let programme = programme {
                VStack(spacing: 12) {
                    ForEach(programme.sortedDays, id: \.key) { sessionKey, session in
                        SessionCard(
                            weekNumber: weekNumber,
                            sessionKey: sessionKey,
                            session: session,
                            isEnabled: !isFutureWeek,
                            isCompleted: viewModel.isSessionCompleted(weekNumber: weekNumber, sessionKey: sessionKey),
                            onTap: {
                                if !isFutureWeek {
                                    selectedSession = SessionSelection(weekNumber: weekNumber, sessionKey: sessionKey)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

struct SessionCard: View {
    let weekNumber: Int
    let sessionKey: String
    let session: Session
    let isEnabled: Bool
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.name)
                        .font(.headline)
                        .foregroundColor(isEnabled ? .primary : .secondary)

                    Text("\(session.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "3C825E"))
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCompleted ? Color(hex: "ABCF78").opacity(0.2) : (isEnabled ? Color.white : Color.gray.opacity(0.1)))
                    .shadow(color: isEnabled ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCompleted ? Color(hex: "3C825E") : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!isEnabled)
    }
}
