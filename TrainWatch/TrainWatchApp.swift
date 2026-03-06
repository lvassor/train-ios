//
//  TrainWatchApp.swift
//  TrainWatch
//
//  Apple Watch companion app for Train
//

import SwiftUI

@main
struct TrainWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityService.shared

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(connectivity)
        }
    }
}
