//
//  ExerciseDemoHistoryView.swift
//  TrainSwift
//
//  Unified Demo/History view for browsing exercises outside of workout context.
//  Used by: Library, Dashboard program browse
//  Reuses the same ExerciseDemoTab and ExerciseHistoryView components as ExerciseLoggerView
//

import SwiftUI

// MARK: - Tab Options for Demo/History only

enum DemoHistoryTabOption: String, CaseIterable, Hashable {
    case demo = "Demo"
    case history = "History"

    var icon: String {
        switch self {
        case .demo: return "play.circle.fill"
        case .history: return "chart.xyaxis.line"
        }
    }
}

// MARK: - Main View

struct ExerciseDemoHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    let exercise: DBExercise

    @State private var selectedTab: DemoHistoryTabOption = .demo

    var body: some View {
        ZStack {
            // Background gradient
            AppGradient.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button and exercise name
                DemoHistoryHeader(
                    exerciseName: exercise.displayName,
                    onBack: { dismiss() }
                )

                // Tab selector
                DemoHistoryTabSelector(selectedTab: $selectedTab)
                    .padding(.top, Spacing.md)

                // Tab content - uses SAME components as ExerciseLoggerView
                if selectedTab == .demo {
                    ExerciseDemoTab(exercise: exercise)
                } else {
                    ExerciseHistoryView(exercise: exercise)
                        .padding(.top, Spacing.sm)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Header

struct DemoHistoryHeader: View {
    let exerciseName: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            // Back button
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.trainTextPrimary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Title
            Text("Exercise Details")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.trainTextPrimary)

            Spacer()

            // Placeholder for balance
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Tab Selector (Pill Style - matches LoggerTabSelector)

struct DemoHistoryTabSelector: View {
    @Binding var selectedTab: DemoHistoryTabOption
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Background pill - sized for 2 tabs
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(0.1)
                    : Color.trainTabBackground)
                .frame(height: 40)

            HStack(spacing: 0) {
                ForEach(DemoHistoryTabOption.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.trainTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                selectedTab == tab ?
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(colorScheme == .dark
                                            ? Color.white.opacity(0.15)
                                            : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(colorScheme == .dark
                                                    ? Color.white.opacity(0.3)
                                                    : Color.black.opacity(0.47), lineWidth: 1)
                                        )
                                : nil
                            )
                    }
                }
            }
        }
        .frame(width: 200, height: 40) // Compact width for 2 tabs
    }
}

// MARK: - Preview

#Preview {
    let mockExercise = try! JSONDecoder().decode(DBExercise.self, from: """
    {
        "exercise_id": "1",
        "canonical_name": "barbell_bench_press",
        "display_name": "Barbell Bench Press",
        "movement_pattern": "horizontal_push",
        "equipment_type": "Barbell",
        "equipment_category": "Barbell",
        "complexity_level": 3,
        "primary_muscle": "Chest",
        "secondary_muscle": "Triceps",
        "instructions": "Lie on bench\\nGrip barbell\\nLower to chest\\nPress up",
        "is_active": 1,
        "is_in_programme": 1
    }
    """.data(using: .utf8)!)

    return NavigationStack {
        ExerciseDemoHistoryView(exercise: mockExercise)
    }
}
