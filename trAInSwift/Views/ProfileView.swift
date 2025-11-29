//
//  ProfileView.swift
//  trAInApp
//
//  User profile and settings
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared
    @State private var showLogoutConfirmation = false
    @State private var shouldRestartQuestionnaire = false

    var body: some View {
        NavigationView {
            ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // User Info
                        VStack(spacing: Spacing.md) {
                            Circle()
                                .fill(Color.trainPrimary.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.trainPrimary)
                                )

                            Text(authService.currentUser?.email ?? "")
                                .font(.trainHeadline)
                                .foregroundColor(.trainTextPrimary)

                            if let user = authService.currentUser {
                                Text("Member since \(formatDate(user.createdAt ?? Date()))")
                                    .font(.trainCaption)
                                    .foregroundColor(.trainTextSecondary)
                            }
                        }
                        .padding(.top, Spacing.xl)

                        // Subscription Card
                        SubscriptionInfoCard()
                            .padding(.horizontal, Spacing.lg)

                        // Program Card
                        ProgramCard()
                            .padding(.horizontal, Spacing.lg)

                        // Menu Items
                        VStack(spacing: 0) {
                            ProfileMenuItem(
                                icon: "person.circle",
                                title: "Edit Profile",
                                action: {}
                            )

                            Divider()
                                .padding(.leading, 60)

                            ProfileMenuItem(
                                icon: "arrow.right.circle",
                                title: "Log Out",
                                isDestructive: true,
                                action: {
                                    showLogoutConfirmation = true
                                }
                            )

                            Divider()
                                .padding(.leading, 60)

                            ProfileMenuItem(
                                icon: "trash",
                                title: "Delete Account",
                                isDestructive: true,
                                action: {}
                            )
                        }
                        .appCard()
                        .padding(.horizontal, Spacing.lg)

                        Spacer()
                    }
                }
                .warmDarkGradientBackground()
                .scrollContentBackground(.hidden)
                .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .foregroundColor(.trainPrimary)
                    }
                }
            }
        }
        .confirmationDialog("Log Out", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                authService.logout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : .trainPrimary)
                    .frame(width: 28)

                Text(title)
                    .font(.trainBody)
                    .foregroundColor(isDestructive ? .red : .trainTextPrimary)

                Spacer()

                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.trainTextSecondary)
                }
            }
            .padding(Spacing.md)
        }
    }
}

// MARK: - Subscription Info Card

struct SubscriptionInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Plan")
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Annual Plan")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    Text("£99.99/year")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)

                    Text("Next billing: Jan 15, 2026")
                        .font(.trainCaption)
                        .foregroundColor(.trainTextSecondary)
                }

                Spacer()
            }

            Button(action: {
                // Open iOS subscription management
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Manage Subscription")
                    .font(.trainBodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.trainPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(Spacing.md)
        .appCard()
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared
    @State private var showRetakeConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Programme")
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(authService.getCurrentProgram()?.getProgram()?.type.description ?? "No Programme")
                        .font(.trainBodyMedium)
                        .foregroundColor(.trainTextPrimary)

                    if let program = authService.getCurrentProgram()?.getProgram() {
                        Text("\(program.daysPerWeek) days/week • \(program.sessionDuration.rawValue)")
                            .font(.trainBody)
                            .foregroundColor(.trainTextSecondary)
                    }
                }

                Spacer()
            }

            Button(action: {
                showRetakeConfirmation = true
            }) {
                Text("Retake Quiz")
                    .font(.trainBodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.trainPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(Spacing.md)
        .appCard()
        .confirmationDialog("Retake Quiz", isPresented: $showRetakeConfirmation, titleVisibility: .visible) {
            Button("Retake Quiz", role: .destructive) {
                // Log out to restart questionnaire flow
                // This will clear the user session and allow them to take the quiz again
                authService.logout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will log you out and let you retake the quiz to create a new programme. Continue?")
        }
    }
}

#Preview {
    ProfileView()
}
