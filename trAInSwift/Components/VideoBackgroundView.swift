//
//  VideoBackgroundView.swift
//  trAInSwift
//
//  Reusable video background component with seamless looping
//

import SwiftUI
import AVKit
import AVFoundation

class VideoPlayerView: UIView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    // This is the key - override layerClass to return AVPlayerLayer
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    // Cast the layer to AVPlayerLayer for easy access
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Set dark background to prevent white flash
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupVideo(named videoName: String, extension videoExtension: String = "mp4") {
        print("🎥 VideoPlayerView: Setting up video: \(videoName).\(videoExtension)")

        guard let videoURL = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            print("❌ Video file not found: \(videoName).\(videoExtension)")
            return
        }

        print("✅ Video file found: \(videoURL.absoluteString)")

        // Create asset and player
        let asset = AVURLAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVQueuePlayer(playerItem: playerItem)

        guard let player = player else { return }

        // Configure player
        player.isMuted = true
        player.allowsExternalPlayback = false
        player.automaticallyWaitsToMinimizeStalling = false

        // Set up looping
        looper = AVPlayerLooper(player: player, templateItem: playerItem)

        // Configure the player layer for FULL SCREEN edge-to-edge
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill  // Fill and crop, no distortion

        // Black background set in init prevents flash during video load

        // Start playing
        player.play()
        print("▶️ Started playing video: \(videoName)")
    }

    func cleanup() {
        player?.pause()
        player?.removeAllItems()
        looper = nil
        player = nil
        playerLayer.player = nil
        print("🧹 VideoPlayerView cleaned up")
    }
}

struct VideoBackgroundView: UIViewRepresentable {
    let videoName: String
    let videoExtension: String

    init(videoName: String, videoExtension: String = "mp4") {
        self.videoName = videoName
        self.videoExtension = videoExtension
    }

    func makeUIView(context: Context) -> VideoPlayerView {
        let videoView = VideoPlayerView()
        videoView.setupVideo(named: videoName, extension: videoExtension)
        return videoView
    }

    func updateUIView(_ uiView: VideoPlayerView, context: Context) {
        // Layout will be handled automatically by VideoPlayerView.layoutSubviews
    }

    static func dismantleUIView(_ uiView: VideoPlayerView, coordinator: ()) {
        uiView.cleanup()
    }
}

// MARK: - Convenient initializers
extension VideoBackgroundView {
    init(name: String) {
        self.init(videoName: name, videoExtension: "mp4")
    }
}