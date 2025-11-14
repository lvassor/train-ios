//
//  ProgramLoadingView.swift
//  trAInApp
//
//  Loading screen with animated checklist
//

import SwiftUI

struct ProgramLoadingView: View {
    @State private var progress: Double = 0.0
    @State private var currentStage = 0

    let onComplete: () -> Void

    let stages = [
        "Analysing your goals",
        "Selecting exercises",
        "Structuring your program"
    ]

    var body: some View {
        ZStack {
            Color.trainBackground
                .ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // Loading spinner
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .trainPrimary))
                    .scaleEffect(1.5)

                // Title
                Text("Building Your Program")
                    .font(.trainTitle)
                    .foregroundColor(.trainTextPrimary)

                // Progress bar with percentage
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.trainCaption)
                            .foregroundColor(.trainTextSecondary)

                        Spacer()

                        Text("\(Int(progress * 100))%")
                            .font(.trainCaption)
                            .foregroundColor(.trainPrimary)
                            .fontWeight(.medium)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.trainBorder)
                                .frame(height: 8)
                                .cornerRadius(4)

                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.trainPrimary, Color.trainLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 8)
                                .cornerRadius(4)
                                .animation(.linear(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 32)

                // Checklist
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        ChecklistItem(
                            title: stage,
                            status: index < currentStage ? .completed : (index == currentStage ? .inProgress : .pending)
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .onAppear {
                startLoading()
            }
        }
    }

    private func startLoading() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.01

                // Update stage based on progress
                if progress > 0.33 && currentStage == 0 {
                    withAnimation {
                        currentStage = 1
                    }
                } else if progress > 0.66 && currentStage == 1 {
                    withAnimation {
                        currentStage = 2
                    }
                } else if progress >= 1.0 {
                    withAnimation {
                        currentStage = 3
                    }
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete()
                    }
                }
            }
        }
    }
}

struct ChecklistItem: View {
    let title: String
    let status: Status

    enum Status {
        case completed
        case inProgress
        case pending
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 24, height: 24)

                if status == .completed {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                } else if status == .inProgress {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                }
            }

            Text(title)
                .font(.trainBody)
                .foregroundColor(status == .pending ? Color.trainTextSecondary.opacity(0.5) : .trainTextPrimary)
        }
    }

    private var statusColor: Color {
        switch status {
        case .completed:
            return .trainPrimary
        case .inProgress:
            return .trainLight
        case .pending:
            return .trainBorder
        }
    }
}
