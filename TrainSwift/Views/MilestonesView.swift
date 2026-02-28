//
//  MilestonesView.swift
//  TrainSwift
//
//  Milestones and achievements screen with category-tinted progress cards
//

import SwiftUI

struct MilestonesView: View {
    @Environment(\.dismiss) var dismiss

    @State private var allMilestones: [MilestoneProgress] = []
    @State private var topStats = MilestoneTopStats(pbsAchieved: 0, workoutsCompleted: 0, progressionStreak: 0)
    @State private var recentPBs: [RecentPB] = []
    @State private var isLoaded = false

    private let service = MilestoneService()

    private var recentlyAchieved: [MilestoneProgress] {
        allMilestones
            .filter { $0.isCompleted }
            .sorted { ($0.achievedDate ?? .distantPast) > ($1.achievedDate ?? .distantPast) }
    }

    private var upcoming: [MilestoneProgress] {
        // Show the next unfinished milestone from each category
        var result: [MilestoneProgress] = []
        for category in MilestoneCategory.allCases {
            if let next = allMilestones
                .filter({ $0.category == category && !$0.isCompleted })
                .sorted(by: { $0.progress > $1.progress })
                .first {
                result.append(next)
            }
        }
        return result
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                // Top Stats
                topStatsSection

                // Recently Achieved
                if !recentlyAchieved.isEmpty {
                    milestoneSection(title: "Recently Achieved", milestones: Array(recentlyAchieved.prefix(5)))
                }

                // Upcoming Milestones
                if !upcoming.isEmpty {
                    milestoneSection(title: "Upcoming Milestones", milestones: upcoming)
                }

                // Streak Milestones
                if isLoaded {
                    streakMilestonesSection
                }

                // Recent PBs
                if !recentPBs.isEmpty {
                    recentPBsSection
                }

                // Empty state
                if !isLoaded {
                    ProgressView()
                        .tint(.trainTextSecondary)
                        .padding(.top, Spacing.xxl)
                } else if allMilestones.allSatisfy({ !$0.isCompleted }) && recentPBs.isEmpty {
                    emptyState
                }

                Spacer().frame(height: Spacing.xxl)
            }
            .padding(.top, Spacing.md)
        }
        .charcoalGradientBackground()
        .navigationTitle("Milestones")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
        }
    }

    // MARK: - Top Stats

    private var topStatsSection: some View {
        HStack(spacing: Spacing.sm) {
            StatBox(
                value: "\(topStats.pbsAchieved)",
                label: "PBs achieved",
                icon: "trophy.fill"
            )

            // Center flame - decorative, no card background
            VStack(spacing: Spacing.xs) {
                FlameView()
                    .frame(width: 44, height: 44)
                    .clipped()

                Text("\(topStats.progressionStreak)")
                    .font(.trainSmallNumber).fontWeight(.bold)
                    .foregroundColor(.trainTextPrimary)

                Text("Progression Streak")
                    .font(.trainCaptionSmall)
                    .foregroundColor(.trainTextSecondary)
            }
            .frame(maxWidth: .infinity)

            StatBox(
                value: "\(topStats.workoutsCompleted)",
                label: "Workouts\ncompleted",
                icon: "dumbbell.fill"
            )
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Milestone Section

    private func milestoneSection(title: String, milestones: [MilestoneProgress]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)
                .padding(.horizontal, Spacing.lg)

            VStack(spacing: Spacing.sm) {
                ForEach(milestones) { milestone in
                    MilestoneCard(milestone: milestone)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Streak Milestones

    private var streakMilestonesSection: some View {
        let streakThresholds: [(days: Int, title: String, icon: String)] = [
            (7, "7-Day Streak", "flame.fill"),
            (30, "30-Day Streak", "flame.fill"),
            (100, "100-Day Streak", "flame.fill")
        ]
        let currentStreakValue = topStats.progressionStreak

        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Streak Milestones")
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)
                .padding(.horizontal, Spacing.lg)

            VStack(spacing: Spacing.sm) {
                ForEach(streakThresholds, id: \.days) { milestone in
                    let progress = min(1.0, Double(currentStreakValue) / Double(milestone.days))
                    let isAchieved = currentStreakValue >= milestone.days

                    StreakMilestoneCard(
                        title: milestone.title,
                        icon: milestone.icon,
                        progress: progress,
                        isAchieved: isAchieved,
                        currentValue: currentStreakValue,
                        targetValue: milestone.days
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Recent PBs

    private var recentPBsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent PBs")
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)
                .padding(.horizontal, Spacing.lg)

            TabView {
                ForEach(recentPBs) { pb in
                    RecentPBCard(pb: pb)
                        .padding(.horizontal, Spacing.lg)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 130)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.trainPrimary.opacity(0.1))
                    .frame(width: IconSize.display, height: IconSize.display)

                Image(systemName: "trophy.fill")
                    .font(.system(size: IconSize.xl))
                    .foregroundColor(.trainPrimary)
            }

            VStack(spacing: Spacing.sm) {
                Text("Start Training")
                    .font(.trainTitle2)
                    .foregroundColor(.trainTextPrimary)

                Text("Complete workouts to unlock milestones and track your progress")
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .padding(.top, Spacing.xl)
    }

    // MARK: - Data Loading

    private func loadData() {
        Task.detached(priority: .userInitiated) {
            let milestones = service.computeAllMilestones()
            let stats = service.computeTopStats()
            let pbs = service.computeRecentPBs()

            await MainActor.run {
                allMilestones = milestones
                topStats = stats
                recentPBs = pbs
                isLoaded = true
            }
        }
    }
}

// MARK: - Stat Box

private struct StatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.trainCaptionSmall)
                    .foregroundColor(.trainPrimary)

                Text(value)
                    .font(.trainSmallNumber).fontWeight(.bold)
                    .foregroundColor(.trainTextPrimary)
            }

            Text(label)
                .font(.trainCaptionSmall)
                .foregroundColor(.trainTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(Color.trainTextSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Streak Stat Box (Lottie flame)

private struct StreakStatBox: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                FlameView()
                    .frame(width: IconSize.sm, height: IconSize.sm)

                Text(value)
                    .font(.trainSmallNumber).fontWeight(.bold)
                    .foregroundColor(.trainTextPrimary)
            }

            Text(label)
                .font(.trainCaptionSmall)
                .foregroundColor(.trainTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(Color.trainTextSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Milestone Card

private struct MilestoneCard: View {
    let milestone: MilestoneProgress

    @State private var animatedProgress: Double = 0

    private var categoryColor: Color {
        milestone.category.color
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: IconSize.xl, height: IconSize.xl)

                Image(systemName: milestone.category.icon)
                    .font(.system(size: IconSize.sm))
                    .foregroundColor(categoryColor)
            }

            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(milestone.title)
                        .font(.trainCaptionLarge).fontWeight(.medium)
                        .foregroundColor(.trainTextPrimary)

                    Spacer()

                    if milestone.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: IconSize.sm))
                            .foregroundColor(categoryColor)
                    } else {
                        Text(milestone.definition.progressDescription(current: milestone.currentValue))
                            .font(.trainCaptionSmall)
                            .foregroundColor(.trainTextSecondary)
                    }
                }

                // Progress bar (animated)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: CornerRadius.xxs)
                            .fill(Color.trainTextSecondary.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: CornerRadius.xxs)
                            .fill(categoryColor.opacity(0.75))
                            .frame(width: geometry.size.width * animatedProgress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(
                    milestone.isCompleted
                        ? categoryColor.opacity(0.3)
                        : Color.trainTextSecondary.opacity(0.2),
                    lineWidth: 1
                )
        )
        .onAppear {
            withAnimation(.easeOut(duration: AnimationDuration.celebration)) {
                animatedProgress = milestone.progress
            }
        }
    }
}

// MARK: - Recent PB Card

private struct RecentPBCard: View {
    let pb: RecentPB

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(pb.exerciseName)
                .font(.trainBody).fontWeight(.semibold)
                .foregroundColor(.trainTextPrimary)
                .lineLimit(1)

            HStack(spacing: Spacing.sm) {
                Text("\(Int(pb.previousWeight))kg")
                    .font(.trainHeadline).fontWeight(.medium)
                    .foregroundColor(.trainTextSecondary)

                Image(systemName: "arrow.right")
                    .font(.trainCaption).fontWeight(.semibold)
                    .foregroundColor(MilestoneCategory.progression.color)

                Text("\(Int(pb.newWeight))kg")
                    .font(.trainHeadline).fontWeight(.bold)
                    .foregroundColor(MilestoneCategory.progression.color)

                Spacer()

                Text(pb.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.trainCaptionSmall)
                    .foregroundColor(.trainTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(MilestoneCategory.progression.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Streak Milestone Card

private struct StreakMilestoneCard: View {
    let title: String
    let icon: String
    let progress: Double
    let isAchieved: Bool
    let currentValue: Int
    let targetValue: Int

    @State private var animatedProgress: Double = 0

    private let streakColor = MilestoneCategory.streak.color

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Streak icon
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                    .fill(streakColor.opacity(0.15))
                    .frame(width: IconSize.xl, height: IconSize.xl)

                Image(systemName: icon)
                    .font(.system(size: IconSize.sm))
                    .foregroundColor(streakColor)
            }

            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(title)
                        .font(.trainCaptionLarge).fontWeight(.medium)
                        .foregroundColor(.trainTextPrimary)

                    Spacer()

                    if isAchieved {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: IconSize.sm))
                            .foregroundColor(streakColor)
                    } else {
                        Text("\(currentValue)/\(targetValue) days")
                            .font(.trainCaptionSmall)
                            .foregroundColor(.trainTextSecondary)
                    }
                }

                // Progress bar (animated)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: CornerRadius.xxs)
                            .fill(Color.trainTextSecondary.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: CornerRadius.xxs)
                            .fill(streakColor.opacity(0.75))
                            .frame(width: geometry.size.width * animatedProgress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(
                    isAchieved
                        ? streakColor.opacity(0.3)
                        : Color.trainTextSecondary.opacity(0.2),
                    lineWidth: 1
                )
        )
        .onAppear {
            withAnimation(.easeOut(duration: AnimationDuration.celebration)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MilestonesView()
    }
}
