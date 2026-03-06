//
//  WatchRestTimerView.swift
//  TrainWatch
//
//  Full-screen rest timer overlay with circular countdown
//

import SwiftUI

struct WatchRestTimerView: View {
    @EnvironmentObject var connectivity: WatchConnectivityService
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var totalSeconds: Int {
        connectivity.restSecondsRemaining ?? 0
    }

    private var remaining: Int {
        guard let end = connectivity.restEndDate else { return 0 }
        return max(0, Int(end.timeIntervalSince(now)))
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remaining) / Double(totalSeconds)
    }

    private var isComplete: Bool {
        remaining <= 0 && connectivity.restEndDate != nil
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                Text("REST")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(2)

                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            isComplete ? Color.green : Color.orange,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: remaining)

                    // Countdown text
                    if isComplete {
                        VStack(spacing: 2) {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("GO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    } else {
                        VStack(spacing: 0) {
                            Text("\(remaining)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("sec")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 100, height: 100)

                // Skip button
                Button {
                    connectivity.restEndDate = nil
                    connectivity.restSecondsRemaining = nil
                } label: {
                    Text(isComplete ? "Dismiss" : "Skip")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }
        }
        .onReceive(timer) { time in
            now = time
            // Auto-dismiss 3 seconds after completion
            if let end = connectivity.restEndDate,
               Date().timeIntervalSince(end) > 3 {
                connectivity.restEndDate = nil
                connectivity.restSecondsRemaining = nil
            }
        }
    }
}
