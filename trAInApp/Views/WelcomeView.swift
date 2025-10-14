//
//  WelcomeView.swift
//  trAInApp
//
//  Updated with new design
//

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

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

                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.trainBodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.trainPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}
