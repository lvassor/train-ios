//
//  CalendarSessionDetailView.swift
//  TrainSwift
//
//  Displays workout data for a selected calendar day with multi-session cycling
//

import SwiftUI
import CoreData

struct CalendarSessionDetailView: View {
    let sessions: [CDWorkoutSession]
    let userProgram: WorkoutProgram
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.managedObjectContext) private var viewContext

    @State private var currentIndex: Int = 0
    @State private var personalBests: [String: Double] = [:]
    @State private var sessionStats: SessionStats?

    private var currentSession: CDWorkoutSession {
        sessions[currentIndex]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if let stats = sessionStats {
                    SessionSummaryHeader(
                        session: currentSession,
                        stats: stats
                    )
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                }

                ExerciseLogCardsSection(
                    session: currentSession,
                    previousSession: getPreviousSession(),
                    personalBests: personalBests
                )
                .padding(.horizontal, Spacing.lg)

                Spacer()
                    .frame(height: Spacing.xxl)
            }
        }
        .charcoalGradientBackground()
        .scrollContentBackground(.hidden)
        .navigationTitle(currentSession.sessionName ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if sessions.count > 1 {
                    Button(action: cycleForward) {
                        HStack(spacing: Spacing.xs) {
                            Text("\(currentIndex + 1)/\(sessions.count)")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: IconSize.sm, weight: .semibold))
                                .foregroundColor(.trainPrimary)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadStats()
        }
    }

    // MARK: - Multi-Session Cycling

    private func cycleForward() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentIndex = (currentIndex + 1) % sessions.count
        }
        loadStats()
    }

    // MARK: - Stats Calculation

    private func loadStats() {
        guard let userId = authService.currentUser?.id else { return }

        let sessionName = currentSession.sessionName ?? ""

        // Fetch all sessions of this workout type for PB calculation
        let request = CDWorkoutSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "userId == %@ AND sessionName == %@",
            userId as CVarArg,
            sessionName
        )
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]

        do {
            let allSessions = try viewContext.fetch(request)

            // Calculate personal bests
            var bests: [String: Double] = [:]
            for session in allSessions {
                for exercise in session.getLoggedExercises() {
                    let maxWeight = exercise.sets.map { $0.weight }.max() ?? 0
                    if let currentBest = bests[exercise.exerciseName] {
                        bests[exercise.exerciseName] = max(currentBest, maxWeight)
                    } else {
                        bests[exercise.exerciseName] = maxWeight
                    }
                }
            }
            personalBests = bests

            // Calculate session stats (vs previous session of same type)
            let previous = allSessions.first(where: {
                $0 != currentSession && ($0.completedAt ?? .distantPast) < (currentSession.completedAt ?? .distantPast)
            })
            sessionStats = SessionStats(current: currentSession, previous: previous)
        } catch {
            AppLogger.logDatabase("Failed to load session stats: \(error)", level: .error)
        }
    }

    private func getPreviousSession() -> CDWorkoutSession? {
        guard let userId = authService.currentUser?.id else { return nil }

        let sessionName = currentSession.sessionName ?? ""
        let request = CDWorkoutSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "userId == %@ AND sessionName == %@ AND completedAt < %@",
            userId as CVarArg,
            sessionName,
            (currentSession.completedAt ?? Date()) as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            return nil
        }
    }
}
