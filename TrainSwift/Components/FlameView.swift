//
//  FlameView.swift
//  TrainSwift
//
//  Lottie animation wrapper for the streak flame icon
//

import SwiftUI
import Lottie

struct FlameView: UIViewRepresentable {
    var size: CGFloat = 32

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: "Fire")
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()

        // Pause when app backgrounds to save battery
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            animationView.pause()
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            animationView.play()
        }

        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
