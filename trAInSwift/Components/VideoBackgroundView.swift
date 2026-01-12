//
//  VideoBackgroundView.swift
//  trAInSwift
//
//  Reusable video background component with seamless looping
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoBackgroundView: UIViewRepresentable {
    let videoName: String
    let videoExtension: String

    init(videoName: String, videoExtension: String = "mov") {
        self.videoName = videoName
        self.videoExtension = videoExtension
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .black // Set background to black instead of clear

        guard let videoURL = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            print("❌ Video file not found: \(videoName).\(videoExtension)")
            print("📁 Bundle path: \(Bundle.main.bundlePath)")

            // Add visual indicator when video fails to load
            let label = UILabel()
            label.text = "Video not found: \(videoName).\(videoExtension)"
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 16)
            containerView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20)
            ])

            return containerView
        }

        print("✅ Video file found: \(videoURL.absoluteString)")

        // Create player with the video URL
        let playerItem = AVPlayerItem(url: videoURL)
        let player = AVQueuePlayer(playerItem: playerItem)

        // Set up looping
        let looper = AVPlayerLooper(player: player, templateItem: playerItem)

        // Store looper to prevent deallocation
        objc_setAssociatedObject(containerView, "looper", looper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // Create player layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = UIColor.black.cgColor
        containerView.layer.addSublayer(playerLayer)

        // Configure player
        player.isMuted = true // No sound for background video

        // Add observer for player item status
        playerItem.addObserver(context.coordinator, forKeyPath: "status", options: [.new, .initial], context: nil)

        player.play()
        print("🎬 Started playing video: \(videoName)")

        // Store player for later use
        objc_setAssociatedObject(containerView, "player", player, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(containerView, "playerLayer", playerLayer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return containerView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "status" {
                if let playerItem = object as? AVPlayerItem {
                    switch playerItem.status {
                    case .readyToPlay:
                        print("✅ Video ready to play")
                    case .failed:
                        print("❌ Video failed to load: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                    case .unknown:
                        print("⚠️ Video status unknown")
                    @unknown default:
                        print("⚠️ Video status unknown default")
                    }
                }
            }
        }
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update player layer frame when view bounds change
        if let playerLayer = objc_getAssociatedObject(uiView, "playerLayer") as? AVPlayerLayer {
            DispatchQueue.main.async {
                playerLayer.frame = uiView.bounds
            }
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        // Clean up player when view is deallocated
        if let player = objc_getAssociatedObject(uiView, "player") as? AVQueuePlayer {
            player.pause()
            player.removeAllItems()
        }
    }
}

// MARK: - Convenient initializers
extension VideoBackgroundView {
    init(name: String) {
        self.init(videoName: name, videoExtension: "mov")
    }
}