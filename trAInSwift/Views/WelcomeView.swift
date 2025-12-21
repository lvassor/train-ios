//
//  WelcomeView.swift
//  trAInApp
//
//  Updated with new design
//

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void
    let onLogin: () -> Void

    var body: some View {
        ZStack {
            AppGradient.background
                .ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                VStack(spacing: 12) {
                    // Logo with text
                    Image("TrainLogoWithText")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)

                    Text("The world's #1\nstrength training app")
                        .font(.trainSubtitle)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 16) {
                    CustomButton(
                        title: "Get Started",
                        action: onContinue
                    )
                    .padding(.horizontal, 16)

                    HStack(spacing: 4) {
                        Text("If you already have an account,")
                            .font(.trainBody)
                            .foregroundColor(.white.opacity(0.8))

                        Button(action: {}) {
                            Text("log in")
                                .font(.trainBody)
                                .foregroundColor(.trainPrimary)
                                .underline()
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}
