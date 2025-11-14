//
//  RestTimerView.swift
//  trAInSwift
//
//  Rest timer component for workout logging
//

import SwiftUI

struct RestTimerView: View {
    let totalSeconds: Int
    let onDismiss: () -> Void

    @State private var secondsRemaining: Int
    @State private var timer: Timer?

    init(totalSeconds: Int, onDismiss: @escaping () -> Void) {
        self.totalSeconds = totalSeconds
        self.onDismiss = onDismiss
        _secondsRemaining = State(initialValue: totalSeconds)
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Timer display
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 16))
                    .foregroundColor(.trainPrimary)

                Text(timeString)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.trainPrimary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)

            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.trainTextSecondary.opacity(0.2), lineWidth: 3)
                    .frame(width: 28, height: 28)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.trainPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
            }

            // Skip button
            Button(action: {
                stopTimer()
                onDismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.trainTextSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.trainPrimary.opacity(0.05))
        .cornerRadius(10)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private var timeString: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(totalSeconds - secondsRemaining) / CGFloat(totalSeconds)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                stopTimer()
                // Optional: play sound/haptic
                onDismiss()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    VStack(spacing: 20) {
        RestTimerView(totalSeconds: 120, onDismiss: {})
            .padding()

        RestTimerView(totalSeconds: 90, onDismiss: {})
            .padding()

        RestTimerView(totalSeconds: 30, onDismiss: {})
            .padding()
    }
    .background(Color.trainBackground)
}
