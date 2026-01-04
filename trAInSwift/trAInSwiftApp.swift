//
//  trAInSwiftApp.swift
//  trAInSwift
//
//  Created by Luke Vassor on 16/10/2025.
//

import SwiftUI
import CoreData

@main
struct trAInSwiftApp: App {
    // Initialize Core Data persistence controller
    let persistenceController = PersistenceController.shared

    // Initialize theme manager
    @StateObject private var themeManager = ThemeManager()

    init() {
        // CRITICAL: Configure UINavigationBar appearance globally to allow gradient through
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        appearance.shadowColor = .clear

        // Apply to all navigation bars
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance

        // Make sure the navigation bar itself is transparent
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().barTintColor = .clear
        UINavigationBar.appearance().backgroundColor = .clear

        // NUCLEAR: Set the window background to clear
        UITableView.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenWrapper {
                ContentView()
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environment(\.cardStyle, .warm) // Set app-wide card style to warm glass
            .environmentObject(themeManager) // Provide theme manager to all views
            .preferredColorScheme(themeManager.currentMode == .light ? .light : .dark)
        }
    }
}
