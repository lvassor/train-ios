//
//  InlineRestTimer.swift
//  TrainSwift
//
//  Non-blocking rest timer component and controller
//

import SwiftUI
import Combine

// MARK: - Inline Rest Timer (Non-blocking)

struct InlineRestTimer: View {
    let totalSeconds: Int
    @Binding var isActive: Bool

    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?

    var body: some View {
        if isActive {
            HStack(spacing: Spacing.md) {
                // Circular progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 28, height: 28)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: timeRemaining)
                }

                // Time remaining
                Text(timeFormatted)
                    .font(.trainBody).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text("Rest")
                    .font(.trainCaption)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // Dismiss button
                Button(action: dismissTimer) {
                    Image(systemName: "xmark")
                        .font(.trainCaptionSmall).fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: IconSize.md, height: IconSize.md)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.trainPrimary.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.8).combined(with: .opacity)
            ))
            .onAppear { startTimer() }
            .onDisappear { stopTimer() }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    resetAndStartTimer()
                } else {
                    stopTimer()
                }
            }
        }
    }

    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(timeRemaining) / CGFloat(totalSeconds)
    }

    private var timeFormatted: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startTimer() {
        timeRemaining = totalSeconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    isActive = false
                }
                stopTimer()
            }
        }
    }

    private func resetAndStartTimer() {
        stopTimer()
        startTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func dismissTimer() {
        withAnimation(.easeOut(duration: 0.3)) {
            isActive = false
        }
        stopTimer()
    }
}

// MARK: - Rest Timer Controller (manages timer state and reset logic)

@MainActor
class RestTimerController: ObservableObject {
    @Published var isActive: Bool = false
    @Published var restSeconds: Int = 0

    func triggerRest(seconds: Int) {
        restSeconds = seconds
        // If timer is already active, this will cause it to reset via onChange
        if isActive {
            // Briefly deactivate to trigger reset
            isActive = false
            Task {
                try? await Task.sleep(for: .milliseconds(50))
                self.isActive = true
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isActive = true
            }
        }
    }
}
