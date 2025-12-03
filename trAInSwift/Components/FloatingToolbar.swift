//
//  FloatingToolbar.swift
//  trAInSwift
//
//  Floating pill-shaped bottom navigation with liquid glass effect
//  Updated: Swapped dumbbell to dashboard (house), videos to exercise library (dumbbell)
//

import SwiftUI

struct FloatingToolbar: View {
    let onDashboard: () -> Void
    let onMilestones: () -> Void
    let onExerciseLibrary: () -> Void
    let onAccount: () -> Void

    @Binding var selectedTab: ToolbarTab

    var body: some View {
        HStack(spacing: 12) {
            // Main toolbar pill with liquid glass effect
            HStack(spacing: 4) {
                ForEach(ToolbarTab.allCases.filter { $0 != .account }, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                        switch tab {
                        case .dashboard: onDashboard()
                        case .milestones: onMilestones()
                        case .library: onExerciseLibrary()
                        case .account: break
                        }
                    }) {
                        // Icon with transparent tint background when selected
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .trainPrimary : .white.opacity(0.7))
                            .frame(width: 48, height: 42)
                            .background(selectedTab == tab ? Color.trainPrimary.opacity(0.15) : Color.clear)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)  // Liquid glass effect - more translucent
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )

            // Account button (separate floating circle)
            Button(action: onAccount) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 50, height: 50)
                    .background(.ultraThinMaterial)  // Liquid glass effect
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

enum ToolbarTab: CaseIterable {
    case dashboard   // Was exercises (dumbbell), now home
    case milestones
    case library     // Was videos (play), now dumbbell for exercise library
    case account

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"        // Changed from dumbbell
        case .milestones: return "rosette"
        case .library: return "dumbbell.fill"       // Changed from play.circle (video)
        case .account: return "person.circle.fill"
        }
    }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .milestones: return "Milestones"
        case .library: return "Library"
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
                onDashboard: {},
                onMilestones: {},
                onExerciseLibrary: {},
                onAccount: {},
                selectedTab: .constant(.dashboard)
            )
        }
    }
}
