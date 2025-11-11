//
//  MilestonesView.swift
//  trAInSwift
//
//  Milestones and achievements screen (placeholder)
//

import SwiftUI

struct MilestonesView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.trainBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Trophy icon
                ZStack {
                    Circle()
                        .fill(Color.trainPrimary.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.trainPrimary)
                }

                // Text content
                VStack(spacing: Spacing.md) {
                    Text("Coming Soon")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text("Track your achievements and milestones here")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                Spacer()
            }
        }
        .navigationTitle("Milestones")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.trainTextPrimary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MilestonesView()
    }
}
