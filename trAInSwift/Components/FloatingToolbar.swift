//
//  FloatingToolbar.swift
//  trAInSwift
//
//  Floating pill-shaped bottom navigation with sliding lens glass effect
//  Uses GlassTabBar for the sophisticated Apple Phone app-style interaction
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
            // Main toolbar pill with glass lens effect
            GlassTabBar(
                selectedTab: $selectedTab,
                excludeAccount: true,
                onTabSelected: { tab in
                    switch tab {
                    case .dashboard: onDashboard()
                    case .milestones: onMilestones()
                    case .library: onExerciseLibrary()
                    case .account: break
                    }
                }
            )
            .frame(width: 180)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
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
                    .background(.ultraThinMaterial)
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

enum ToolbarTab: CaseIterable, Hashable {
    case dashboard
    case milestones
    case library
    case account

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .milestones: return "rosette"
        case .library: return "dumbbell.fill"
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
