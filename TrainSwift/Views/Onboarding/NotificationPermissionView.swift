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

    var body: some View {
        ZStack {
            AppGradient.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Bell icon
                ZStack {
                    Circle()
                        .fill(Color.trainPrimary.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "bell.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.trainPrimary)
                }

                // Title and description
                VStack(spacing: 16) {
                    Text("Stay on Track")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Get helpful reminders for your workouts and stay motivated with progress updates.")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    // Enable Notifications Button
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

                    // Skip Button
                    Button(action: {
                        print("📲 [NOTIFICATIONS] User skipped notification permission")
                        onContinue()
                    }) {
                        Text("Maybe Later")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: ButtonHeight.standard)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            print("📲 [NOTIFICATIONS] NotificationPermissionView appeared")
            // Check current permission status
            checkNotificationPermissionStatus()
        }
    }

    private func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    print("📲 [NOTIFICATIONS] Already authorized - auto-continuing")
                    permissionGranted = true
                    onContinue()
                case .denied:
                    print("📲 [NOTIFICATIONS] Previously denied")
                case .notDetermined:
                    print("📲 [NOTIFICATIONS] Not determined - showing permission request")
                default:
                    break
                }
            }
        }
    }

    private func requestNotificationPermission() {
        print("📲 [NOTIFICATIONS] Requesting notification permission...")
        isProcessingPermission = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                isProcessingPermission = false

                if let error = error {
                    print("📲 [NOTIFICATIONS] Error requesting permission: \(error)")
                } else if granted {
                    print("📲 [NOTIFICATIONS] ✅ Permission granted")
                    permissionGranted = true
                } else {
                    print("📲 [NOTIFICATIONS] ❌ Permission denied")
                }

                // Continue regardless of permission result
                print("📲 [NOTIFICATIONS] Proceeding to next step")
                onContinue()
            }
        }
    }
}

#Preview {
    NotificationPermissionView(
        onContinue: {
            print("Continue tapped")
        }
    )
}