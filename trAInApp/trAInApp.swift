//
//  trAInApp.swift
//  trAInApp
//
//  Created by Claude Code on 2025-10-06.
//

import SwiftUI

@main
struct trAInApp: App {
    @StateObject private var viewModel = WorkoutViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
