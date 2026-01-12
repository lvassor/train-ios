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

        guard let videoURL = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            print("Video file not found: \(videoName).\(videoExtension)")
            return containerView
        }

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
        containerView.layer.addSublayer(playerLayer)

        // Configure player
        player.isMuted = true // No sound for background video
        player.play()

        // Store player for later use
        objc_setAssociatedObject(containerView, "player", player, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(containerView, "playerLayer", playerLayer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update player layer frame when view bounds change
        if let playerLayer = objc_getAssociatedObject(uiView, "playerLayer") as? AVPlayerLayer {
            DispatchQueue.main.async {
                playerLayer.frame = uiView.bounds
            }
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
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