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
            HStack(spacing: 0) {
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
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .medium))

                            Text(tab.title)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? Color(hex: "#FF7A00") : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
            .frame(height: 56)
            .background(
                ZStack {
                    Color.white.opacity(0.15)
                    Color(hex: "#D2691E").opacity(0.05)
                }
                .background(.ultraThinMaterial)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 4)

            // Account button (separate floating circle)
            Button(action: onAccount) {
                ZStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                .frame(width: 50, height: 50)
                .background(
                    ZStack {
                        Color.white.opacity(0.15)
                        Color(hex: "#D2691E").opacity(0.05)
                    }
                    .background(.ultraThinMaterial)
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 4)
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
        LinearGradient(
            colors: [Color(hex: "#3D2A1A"), Color(hex: "#1A1410")],
            startPoint: .top,
            endPoint: .bottom
        )
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
