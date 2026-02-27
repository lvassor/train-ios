//
//  ExerciseMediaPlayer.swift
//  TrainSwift
//
//  Video player component for exercise demonstrations
//  All exercises use Bunny Stream iframe embeds via WKWebView
//

import SwiftUI
import WebKit

// MARK: - Exercise Media Player

struct ExerciseMediaPlayer: View {
    let exerciseId: String
    @State private var isLoading = true

    var body: some View {
        if let guid = ExerciseMediaMapping.videoGuid(for: exerciseId) {
            BunnyVideoPlayer(videoGuid: guid, isLoading: $isLoading)
        } else {
            mediaPlaceholder(message: "Demo coming soon")
        }
    }

    private func mediaPlaceholder(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "play.slash.fill")
                .font(.system(size: IconSize.xl))
                .foregroundColor(.trainTextSecondary.opacity(0.5))

            Text(message)
                .font(.trainBody)
                .foregroundColor(.trainTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(Color.trainBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
    }
}

// MARK: - Bunny Video Player (WebView-based for iframe embed)

struct BunnyVideoPlayer: View {
    let videoGuid: String
    @Binding var isLoading: Bool
    @State private var showFullscreen = false

    var body: some View {
        ZStack {
            // Video iframe embed
            BunnyVideoWebView(
                videoGuid: videoGuid,
                isLoading: $isLoading
            )
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))

            // Loading overlay
            if isLoading {
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(Color.trainBackground)
                    .frame(height: 220)
                    .overlay {
                        ProgressView()
                            .tint(.trainPrimary)
                    }
            }

            // Fullscreen button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showFullscreen = true }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.trainCaption).fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(Spacing.sm)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(Spacing.sm)
                }
                Spacer()
            }
            .opacity(isLoading ? 0 : 1)
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenVideoPlayer(videoGuid: videoGuid)
        }
    }
}

// MARK: - Bunny Video WebView (iframe embed)

struct BunnyVideoWebView: UIViewRepresentable {
    let videoGuid: String
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let libraryId = BunnyConfig.libraryId
        let embedURL = "https://iframe.mediadelivery.net/embed/\(libraryId)/\(videoGuid)?autoplay=false&loop=true&muted=false&preload=true"

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; background: transparent; overflow: hidden; }
                .video-container {
                    position: relative;
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                }
                iframe {
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    width: 177.78%; /* 16:9 aspect ratio scaling */
                    height: 100%;
                    transform: translate(-50%, -50%);
                    border: none;
                }
            </style>
        </head>
        <body>
            <div class="video-container">
                <iframe
                    src="\(embedURL)"
                    loading="lazy"
                    allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture"
                    allowfullscreen="true">
                </iframe>
            </div>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: BunnyVideoWebView

        init(_ parent: BunnyVideoWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            self.parent.isLoading = false
        }
    }
}

// MARK: - Fullscreen Video Player

struct FullscreenVideoPlayer: View {
    let videoGuid: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            BunnyVideoWebView(videoGuid: videoGuid, isLoading: $isLoading)
                .ignoresSafeArea()

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.trainBody).fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(Spacing.smd)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.lg) {
        ExerciseMediaPlayer(exerciseId: "EX001")
            .padding()

        ExerciseMediaPlayer(exerciseId: "INVALID")
            .padding()
    }
    .background(Color.trainBackground)
}
