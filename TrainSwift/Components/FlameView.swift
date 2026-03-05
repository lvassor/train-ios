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

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let animationView = LottieAnimationView(name: "Fire")
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)

        // Pin the Lottie view to the container edges so SwiftUI .frame() controls sizing
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        animationView.play()
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
