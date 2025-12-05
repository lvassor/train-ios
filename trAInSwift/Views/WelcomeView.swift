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

                VStack(spacing: 16) {
                    Text("train.")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.trainPrimary)
                        .tracking(1)

                    Text("built for you")
                        .font(.trainSubtitle)
                        .foregroundColor(.white)
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

                        Button(action: onLogin) {
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
