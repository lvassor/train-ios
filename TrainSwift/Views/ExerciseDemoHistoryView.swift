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

    var localizedName: String {
        switch self {
        case .demo: return String(localized: "Demo")
        case .history: return String(localized: "History")
        }
    }

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
                    .font(.trainBodyMedium).fontWeight(.semibold)
                    .foregroundColor(.trainTextPrimary)
                    .frame(width: ElementHeight.touchTarget, height: ElementHeight.touchTarget)
            }

            Spacer()

            // Title
            Text("Exercise Details")
                .font(.trainBody).fontWeight(.semibold)
                .foregroundColor(.trainTextPrimary)

            Spacer()

            // Placeholder for balance
            Color.clear
                .frame(width: ElementHeight.touchTarget, height: ElementHeight.touchTarget)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Tab Selector (Pill Style - matches LoggerTabSelector)

struct DemoHistoryTabSelector: View {
    @Binding var selectedTab: DemoHistoryTabOption

    var body: some View {
        ZStack {
            // Background pill - sized for 2 tabs
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(height: ElementHeight.tabSelector)

            HStack(spacing: 0) {
                ForEach(DemoHistoryTabOption.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        Text(tab.localizedName)
                            .font(.trainBody)
                            .foregroundColor(.trainTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: ElementHeight.tabSelector)
                            .background(
                                selectedTab == tab ?
                                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                        .fill(Color.trainSurface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                                .stroke(Color.trainBorderSubtle.opacity(0.5), lineWidth: 1)
                                        )
                                : nil
                            )
                    }
                }
            }
        }
        .frame(width: 200, height: ElementHeight.tabSelector) // Compact width for 2 tabs
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
