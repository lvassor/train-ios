//
//  FloatingToolbar.swift
//  trAInSwift
//
//  Native TabView wrapper that triggers sheets for non-dashboard tabs
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
    @State private var showMilestones = false
    @State private var showLibrary = false
    @State private var showAccount = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard - actual content
            Tab(ToolbarTab.dashboard.title, systemImage: ToolbarTab.dashboard.icon, value: .dashboard) {
                dashboardContent()
            }

            // Milestones - placeholder that triggers sheet
            Tab(ToolbarTab.milestones.title, systemImage: ToolbarTab.milestones.icon, value: .milestones) {
                Color.clear
            }

            // Library - placeholder that triggers sheet
            Tab(ToolbarTab.library.title, systemImage: ToolbarTab.library.icon, value: .library) {
                Color.clear
            }

            // Account - visually distinct trailing tab (like Search in Apple docs)
            Tab(value: .account, role: .search) {
                Color.clear
            } label: {
                Label(ToolbarTab.account.title, systemImage: ToolbarTab.account.icon)
            }
        }
        .tint(Color.trainPrimary)
        .onChange(of: selectedTab) { _, newTab in
            switch newTab {
            case .dashboard:
                break
            case .milestones:
                showMilestones = true
            case .library:
                showLibrary = true
            case .account:
                showAccount = true
            }
        }
        .sheet(isPresented: $showMilestones, onDismiss: {
            selectedTab = .dashboard
        }) {
            NavigationStack {
                MilestonesView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showMilestones = false
                            }
                            .foregroundColor(.trainPrimary)
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showLibrary, onDismiss: {
            selectedTab = .dashboard
        }) {
            NavigationStack {
                CombinedLibraryView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showLibrary = false
                            }
                            .foregroundColor(.trainPrimary)
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showAccount, onDismiss: {
            selectedTab = .dashboard
        }) {
            ProfileView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .presentationBackground(.clear)
        }
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
