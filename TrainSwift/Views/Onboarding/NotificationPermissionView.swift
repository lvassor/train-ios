//
//  NotificationPermissionView.swift
//  TrainSwift
//
//  Turn on notifications screen (Step 18)
//

import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    let onContinue: () -> Void

    @State private var isProcessingPermission = false
    @State private var permissionGranted = false
    @State private var permissionDenied: Bool = false

    var body: some View {
        ZStack {
            AppGradient.background
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Bell icon
                ZStack {
                    Circle()
                        .fill(Color.trainPrimary.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "bell.fill")
                        .font(.system(size: IconSize.xl))
                        .foregroundColor(.trainPrimary)
                }

                // Title and description
                VStack(spacing: Spacing.md) {
                    Text("Stay on Track")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Get helpful reminders for your workouts and stay motivated with progress updates.")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    notificationBullet(icon: "timer", text: "Rest timer alerts when your break is over")
                    notificationBullet(icon: "calendar.badge.clock", text: "Workout reminders to stay consistent")
                    notificationBullet(icon: "flame.fill", text: "Streak updates to keep you motivated")
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.md)

                Spacer()

                // Buttons
                VStack(spacing: Spacing.md) {
                    if permissionDenied {
                        // Denied state - show Open Settings button
                        Button(action: openAppSettings) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "gear")
                                    .font(.trainBodyMedium)
                                Text("Open Settings")
                                    .font(.trainBodyMedium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: ButtonHeight.standard)
                            .background(Color.trainPrimary)
                            .cornerRadius(CornerRadius.md)
                        }

                        Text("Notifications were previously denied. Enable them in Settings \u{2192} train. \u{2192} Notifications.")
                            .font(.trainCaptionSmall)
                            .foregroundColor(.trainTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    } else {
                        // Normal state - Enable Notifications button
                        Button(action: requestNotificationPermission) {
                            HStack {
                                if isProcessingPermission {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isProcessingPermission ? "Requesting Permission..." : "Enable Notifications")
                                    .font(.trainBodyMedium)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: ButtonHeight.standard)
                            .background(Color.trainPrimary)
                            .cornerRadius(CornerRadius.md)
                        }
                        .disabled(isProcessingPermission)
                    }

                    // Skip Button
                    Button(action: {
                        AppLogger.logUI("[NOTIFICATIONS] User skipped notification permission")
                        onContinue()
                    }) {
                        Text("Maybe Later")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: ButtonHeight.standard)
                    }

                    Text("You can enable notifications anytime in Settings \u{2192} train.")
                        .font(.trainCaptionSmall)
                        .foregroundColor(.trainTextSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            AppLogger.logUI("[NOTIFICATIONS] NotificationPermissionView appeared")
            // Check current permission status
            checkNotificationPermissionStatus()
        }
    }

    private func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    AppLogger.logUI("[NOTIFICATIONS] Already authorized - auto-continuing")
                    permissionGranted = true
                    onContinue()
                case .denied:
                    AppLogger.logUI("[NOTIFICATIONS] Previously denied")
                    permissionDenied = true
                case .notDetermined:
                    AppLogger.logUI("[NOTIFICATIONS] Not determined - showing permission request")
                default:
                    break
                }
            }
        }
    }

    private func requestNotificationPermission() {
        AppLogger.logUI("[NOTIFICATIONS] Requesting notification permission...")
        isProcessingPermission = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                isProcessingPermission = false

                if let error = error {
                    AppLogger.logUI("[NOTIFICATIONS] Error requesting permission: \(error)", level: .error)
                } else if granted {
                    AppLogger.logUI("[NOTIFICATIONS] Permission granted")
                    permissionGranted = true
                } else {
                    AppLogger.logUI("[NOTIFICATIONS] Permission denied", level: .warning)
                }

                // Continue regardless of permission result
                AppLogger.logUI("[NOTIFICATIONS] Proceeding to next step")
                onContinue()
            }
        }
    }

    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }

    @ViewBuilder
    private func notificationBullet(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.trainBody)
                .foregroundColor(.trainPrimary)
                .frame(width: IconSize.lg)

            Text(text)
                .font(.trainBody)
                .foregroundColor(.trainTextSecondary)
        }
    }
}

#Preview {
    NotificationPermissionView(
        onContinue: {
            AppLogger.logUI("Continue tapped")
        }
    )
}