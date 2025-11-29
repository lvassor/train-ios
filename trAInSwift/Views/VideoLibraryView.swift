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
            // Gradient base layer
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#a05608"), location: 0.0),
                    .init(color: Color(hex: "#692a00"), location: 0.15),
                    .init(color: Color(hex: "#1A1410"), location: 0.5),
                    .init(color: Color(hex: "#692a00"), location: 0.85),
                    .init(color: Color(hex: "#a05608"), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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
        .scrollContentBackground(.hidden)
        .navigationTitle("Video Library")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        VideoLibraryView()
    }
}
