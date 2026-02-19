//
//  SplashScreen.swift
//  TrainSwift
//
//  Splash screen shown when returning to app from background
//

import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            // Gradient background
            AppGradient.background
                .ignoresSafeArea()

            // Logo centered at 20% of viewport width
            GeometryReader { geometry in
                let logoSize = geometry.size.width * 0.20

                TrainLogoIcon(size: logoSize)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

// MARK: - Train Logo Icon (Diagonal barbell from SVG)

struct TrainLogoIcon: View {
    let size: CGFloat

    // Colors from the isolated SVG
    private let orangeColor = Color(red: 240/255, green: 170/255, blue: 62/255) // #f0aa3e
    private let whiteColor = Color(red: 244/255, green: 245/255, blue: 246/255) // #f4f5f6

    var body: some View {
        // Diagonal barbell logo - single barbell at 45 degrees
        // SVG viewBox is 106.87 x 106.85 mm, we scale to fit our size
        Canvas { context, canvasSize in
            let scale = size / 106.87

            // Transform to center the logo and apply rotation
            // The SVG has a transform offset we need to account for
            let offsetX = (canvasSize.width - size) / 2
            let offsetY = (canvasSize.height - size) / 2

            // Draw each path from the SVG, adjusted to local coordinates
            // Original SVG paths are offset by transform(-356.92, -44.71)
            // We subtract that offset from coordinates

            // Path 1: Top-left weight plate (orange)
            var path1 = Path()
            path1.move(to: CGPoint(x: 15.08 * scale + offsetX, y: 0 * scale + offsetY))
            path1.addLine(to: CGPoint(x: 22.43 * scale + offsetX, y: 7.35 * scale + offsetY))
            path1.addLine(to: CGPoint(x: 7.35 * scale + offsetX, y: 22.43 * scale + offsetY))
            path1.addLine(to: CGPoint(x: 0 * scale + offsetX, y: 15.08 * scale + offsetY))
            path1.closeSubpath()
            context.fill(path1, with: .color(orangeColor))

            // Path 2: Top-left bar section (white)
            var path2 = Path()
            path2.move(to: CGPoint(x: 29.30 * scale + offsetX, y: 5.67 * scale + offsetY))
            path2.addLine(to: CGPoint(x: 36.66 * scale + offsetX, y: 13.02 * scale + offsetY))
            path2.addLine(to: CGPoint(x: 13.05 * scale + offsetX, y: 36.64 * scale + offsetY))
            path2.addLine(to: CGPoint(x: 5.69 * scale + offsetX, y: 29.28 * scale + offsetY))
            path2.closeSubpath()
            context.fill(path2, with: .color(whiteColor))

            // Path 3: Bottom-right weight plate (orange)
            var path3 = Path()
            path3.move(to: CGPoint(x: 91.80 * scale + offsetX, y: 106.85 * scale + offsetY))
            path3.addLine(to: CGPoint(x: 84.44 * scale + offsetX, y: 99.49 * scale + offsetY))
            path3.addLine(to: CGPoint(x: 99.52 * scale + offsetX, y: 84.41 * scale + offsetY))
            path3.addLine(to: CGPoint(x: 106.87 * scale + offsetX, y: 91.77 * scale + offsetY))
            path3.closeSubpath()
            context.fill(path3, with: .color(orangeColor))

            // Path 4: Bottom-right bar section (white)
            var path4 = Path()
            path4.move(to: CGPoint(x: 77.57 * scale + offsetX, y: 101.17 * scale + offsetY))
            path4.addLine(to: CGPoint(x: 70.22 * scale + offsetX, y: 93.81 * scale + offsetY))
            path4.addLine(to: CGPoint(x: 93.83 * scale + offsetX, y: 70.20 * scale + offsetY))
            path4.addLine(to: CGPoint(x: 101.19 * scale + offsetX, y: 77.56 * scale + offsetY))
            path4.closeSubpath()
            context.fill(path4, with: .color(whiteColor))

            // Path 5: Main diagonal bar (orange)
            var path5 = Path()
            path5.move(to: CGPoint(x: 73.48 * scale + offsetX, y: 85.36 * scale + offsetY))
            path5.addLine(to: CGPoint(x: 21.51 * scale + offsetX, y: 33.39 * scale + offsetY))
            path5.addLine(to: CGPoint(x: 33.41 * scale + offsetX, y: 21.49 * scale + offsetY))
            path5.addLine(to: CGPoint(x: 85.38 * scale + offsetX, y: 73.46 * scale + offsetY))
            path5.closeSubpath()
            context.fill(path5, with: .color(orangeColor))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Splash Screen Wrapper

struct SplashScreenWrapper<Content: View>: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = false

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            content()

            if showSplash {
                SplashScreen()
                    .zIndex(100)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background, .inactive:
                // Show splash immediately when leaving active state
                showSplash = true
            case .active:
                // Hide after delay when becoming active
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashScreen()
}
