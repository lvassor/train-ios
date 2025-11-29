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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark) // Dark mode for warm gradient theme
        }
    }
}
