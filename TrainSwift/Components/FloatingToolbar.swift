//
//  FloatingToolbar.swift
//  TrainSwift
//
//  Native TabView wrapper with full navigation views for each tab
//

import SwiftUI

enum ToolbarTab: Int, CaseIterable, Hashable {
    case dashboard = 0
    case milestones = 1
    case library = 2
    case account = 3

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
        case .dashboard: return "Home"
        case .milestones: return "Milestones"
        case .library: return "Library"
        case .account: return "Account"
        }
    }
}

struct MainTabView<DashboardContent: View>: View {
    @ViewBuilder let dashboardContent: () -> DashboardContent

    @State private var selectedTab: ToolbarTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard
            Tab(ToolbarTab.dashboard.title, systemImage: ToolbarTab.dashboard.icon, value: .dashboard) {
                dashboardContent()
            }

            // Milestones - full navigation view
            Tab(ToolbarTab.milestones.title, systemImage: ToolbarTab.milestones.icon, value: .milestones) {
                NavigationStack {
                    MilestonesView()
                }
            }

            // Library - full navigation view
            Tab(ToolbarTab.library.title, systemImage: ToolbarTab.library.icon, value: .library) {
                NavigationStack {
                    CombinedLibraryView()
                }
            }

            // Account
            Tab(value: .account, role: .search) {
                NavigationStack {
                    ProfileView()
                }
            } label: {
                Label(ToolbarTab.account.title, systemImage: ToolbarTab.account.icon)
            }
        }
        .tint(Color.trainPrimary)
    }
}

// MARK: - Legacy FloatingToolbar (kept for compatibility during transition)

struct FloatingToolbar: View {
    let onDashboard: () -> Void
    let onMilestones: () -> Void
    let onExerciseLibrary: () -> Void
    let onAccount: () -> Void

    @Binding var selectedTab: ToolbarTab

    var body: some View {
        // Empty - this is now handled by MainTabView
        EmptyView()
    }
}

// MARK: - Preview

#Preview {
    MainTabView {
        ZStack {
            AppGradient.background
                .ignoresSafeArea()

            Text("Dashboard Content")
                .foregroundColor(.white)
        }
    }
}
