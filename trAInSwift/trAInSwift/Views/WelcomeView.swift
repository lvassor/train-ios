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
            Color.trainDark
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
                    Button(action: onContinue) {
                        Text("Get Started")
                            .font(.trainBodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.trainPrimary)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 20)

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
