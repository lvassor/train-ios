//
//  WatchHomeView.swift
//  TrainWatch
//
//  Main Watch view — shows active workout or waiting state
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var connectivity: WatchConnectivityService

    var body: some View {
        Group {
            if let state = connectivity.workoutState, state.isActive {
                WatchWorkoutView(workoutState: state)
            } else {
                WatchIdleView(isPhoneReachable: connectivity.isPhoneReachable)
            }
        }
    }
}

// MARK: - Idle View (no active workout)

struct WatchIdleView: View {
    let isPhoneReachable: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)

                Text("T")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text("Train")
                .font(.headline)
                .fontWeight(.bold)

            Text("Start a workout on\nyour iPhone")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if !isPhoneReachable {
                HStack(spacing: 4) {
                    Image(systemName: "iphone.slash")
                        .font(.caption2)
                    Text("iPhone not connected")
                        .font(.caption2)
                }
                .foregroundColor(.orange)
                .padding(.top, 4)
            }
        }
        .padding()
    }
}
