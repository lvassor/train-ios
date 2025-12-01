//
//  FloatingToolbar.swift
//  trAInSwift
//
//  Floating pill-shaped bottom navigation with separate account button
//

import SwiftUI

struct FloatingToolbar: View {
    let onExerciseLibrary: () -> Void
    let onMilestones: () -> Void
    let onVideoLibrary: () -> Void
    let onAccount: () -> Void

    @State private var selectedTab: ToolbarTab = .exercises

    var body: some View {
        HStack(spacing: 12) {
            // Main toolbar pill
            HStack(spacing: 8) {
                // Left edge spacing
                Spacer()
                    .frame(width: 12)

                ForEach(ToolbarTab.allCases.filter { $0 != .account }, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                        switch tab {
                        case .exercises: onExerciseLibrary()
                        case .milestones: onMilestones()
                        case .videos: onVideoLibrary()
                        case .account: break
                        }
                    }) {
                        // Icon only - no labels
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .trainPrimary : .white)
                            .frame(width: 44, height: 44)
                    }
                }

                // Right edge spacing
                Spacer()
                    .frame(width: 12)
            }
            .frame(height: 50)
            .warmGlassCard(cornerRadius: 25)

            // Account button (separate floating circle)
            Button(action: onAccount) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .warmGlassCard(cornerRadius: 25)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

enum ToolbarTab: CaseIterable {
    case exercises
    case milestones
    case videos
    case account

    var icon: String {
        switch self {
        case .exercises: return "dumbbell.fill"
        case .milestones: return "rosette"
        case .videos: return "play.circle.fill"
        case .account: return "person.circle.fill"
        }
    }

    var title: String {
        switch self {
        case .exercises: return "Exercises"
        case .milestones: return "Milestones"
        case .videos: return "Videos"
        case .account: return "Account"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppGradient.background
            .ignoresSafeArea()

        VStack {
            Spacer()

            FloatingToolbar(
                onExerciseLibrary: {},
                onMilestones: {},
                onVideoLibrary: {},
                onAccount: {}
            )
        }
    }
}
