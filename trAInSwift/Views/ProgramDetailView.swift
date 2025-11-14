//
//  ProgramDetailView.swift
//  trAInApp
//
//  Detailed view of the user's full program
//

import SwiftUI

struct ProgramDetailView: View {
    @ObservedObject var authService = AuthService.shared

    var body: some View {
        ZStack {
            Color.trainBackground.ignoresSafeArea()

            if let program = authService.getCurrentProgram()?.getProgram() {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Program Info
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(program.type.description)
                                .font(.trainTitle2)
                                .foregroundColor(.trainTextPrimary)

                            Text("\(program.daysPerWeek) days per week • \(program.sessionDuration.rawValue)")
                                .font(.trainBody)
                                .foregroundColor(.trainTextSecondary)

                            Text("\(program.totalWeeks) week program")
                                .font(.trainBody)
                                .foregroundColor(.trainTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                        .background(Color.white)
                        .cornerRadius(CornerRadius.md)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)

                        // Sessions
                        VStack(spacing: Spacing.md) {
                            ForEach(program.sessions) { session in
                                ProgramSessionCard(session: session)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)

                        Spacer()
                            .frame(height: 20)
                    }
                }
            } else {
                Text("No program available")
                    .font(.trainBody)
                    .foregroundColor(.trainTextSecondary)
            }
        }
        .navigationTitle("Your Program")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProgramSessionCard: View {
    let session: ProgramSession

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(session.dayName)
                .font(.trainHeadline)
                .foregroundColor(.trainTextPrimary)

            VStack(spacing: Spacing.sm) {
                ForEach(session.exercises) { exercise in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.exerciseName)
                                .font(.trainBody)
                                .foregroundColor(.trainTextPrimary)

                            Text("\(exercise.sets) sets × \(exercise.repRange) reps")
                                .font(.trainCaption)
                                .foregroundColor(.trainTextSecondary)
                        }

                        Spacer()

                        Text(exercise.primaryMuscle)
                            .font(.trainCaption)
                            .foregroundColor(.trainPrimary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.trainPrimary.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    NavigationView {
        ProgramDetailView()
    }
}
