//
//  VideoLibraryView.swift
//  trAInSwift
//
//  Video library screen (placeholder)
//

import SwiftUI

struct VideoLibraryView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.trainBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Play icon
                ZStack {
                    Circle()
                        .fill(Color.trainPrimary.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.trainPrimary)
                }

                // Text content
                VStack(spacing: Spacing.md) {
                    Text("Coming Soon")
                        .font(.trainTitle)
                        .foregroundColor(.trainTextPrimary)

                    Text("Access workout tutorials and form guides here")
                        .font(.trainBody)
                        .foregroundColor(.trainTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                Spacer()
            }
        }
        .navigationTitle("Video Library")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        VideoLibraryView()
    }
}
