//
//  FloatingToolbar.swift
//  trAInSwift
//
//  Floating bottom navigation with matchedGeometryEffect sliding lens
//

import SwiftUI

struct FloatingToolbar: View {
    let onDashboard: () -> Void
    let onMilestones: () -> Void
    let onExerciseLibrary: () -> Void
    let onAccount: () -> Void

    @Binding var selectedTab: ToolbarTab
    @Namespace private var animation

    private let mainTabs: [ToolbarTab] = [.dashboard, .milestones, .library]

    // Dimensions - doubled height, scaled icons
    private let pillHeight: CGFloat = 70
    private let iconSize: CGFloat = 32
    private let accountButtonSize: CGFloat = 70

    var body: some View {
        HStack(spacing: 12) {
            // Main pill toolbar with sliding lens
            HStack(spacing: 0) {
                ForEach(mainTabs, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                        triggerAction(for: tab)
                    } label: {
                        Image(systemName: tab.icon)
                            .font(.system(size: iconSize, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .frame(height: pillHeight)
                            .background {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(.white.opacity(0.2))
                                        .matchedGeometryEffect(id: "lens", in: animation)
                                }
                            }
                    }
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )

            // Account button (separate floating circle)
            Button(action: onAccount) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: iconSize))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: accountButtonSize, height: accountButtonSize)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 55)  // Reduced width by ~10% each side
        .padding(.bottom, 20)
    }

    private func triggerAction(for tab: ToolbarTab) {
        switch tab {
        case .dashboard: onDashboard()
        case .milestones: onMilestones()
        case .library: onExerciseLibrary()
        case .account: break
        }
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
