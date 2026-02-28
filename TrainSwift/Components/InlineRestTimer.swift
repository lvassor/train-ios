//
//  InlineRestTimer.swift
//  TrainSwift
//
//  Non-blocking rest timer component and controller
//

import SwiftUI
import Combine
import AudioToolbox
import UserNotifications

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
                .accessibilityLabel("Dismiss rest timer")
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.trainPrimary.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.8).combined(with: .opacity)
            ))
            .onAppear {
                startTimer()
                scheduleLocalNotification()
            }
            .onDisappear {
                stopTimer()
                cancelPendingNotification()
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    resetAndStartTimer()
                    scheduleLocalNotification()
                } else {
                    stopTimer()
                    cancelPendingNotification()
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
                // Timer completed — trigger haptic + vibration alert
                triggerTimerCompletionAlert()
                withAnimation(.easeOut(duration: 0.3)) {
                    isActive = false
                }
                stopTimer()
            }
        }
    }

    private func resetAndStartTimer() {
        stopTimer()
        cancelPendingNotification()
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
        cancelPendingNotification()
    }

    // MARK: - Timer Completion Alert

    /// Triggers haptic feedback and system vibration when rest timer completes
    private func triggerTimerCompletionAlert() {
        // Haptic notification feedback (success pattern)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // System vibration for stronger alert
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    // MARK: - Local Notification (for when app is backgrounded)

    private static let notificationIdentifier = "restTimerComplete"

    /// Schedules a local notification so the user gets alerted even if app is backgrounded
    private func scheduleLocalNotification() {
        let center = UNUserNotificationCenter.current()

        // Request permission if not yet granted
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "Rest Complete"
            content.body = "Time to start your next set!"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(totalSeconds),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: Self.notificationIdentifier,
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    /// Cancels the pending notification (timer dismissed early or reset)
    private func cancelPendingNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
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
