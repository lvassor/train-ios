import SwiftUI

struct LaunchScreenView: View {
    // Animation States
    @State private var trimValue: CGFloat = 0.0
    @State private var fillOpacity: Double = 0.0
    @State private var shimmerOffset: CGFloat = -1.2

    // Brand Colors from your SVG Data
    let brandOrange = Color(red: 0.941, green: 0.667, blue: 0.243) // #f0aa3e

    var body: some View {
        // Full screen background
        Color.black.edgesIgnoringSafeArea(.all)
            .overlay(
                VStack {
                    ZStack {
                        // 1. Outline Layer (Drawing)
                        TrainLogoTextShape()
                            .trim(from: 0, to: trimValue)
                            .stroke(Color.white, lineWidth: 2)

                        DumbbellShape()
                            .trim(from: 0, to: trimValue)
                            .stroke(brandOrange, lineWidth: 2)

                        // 2. Solid Fill Layer
                        Group {
                            TrainLogoTextShape().fill(Color.white)
                            DumbbellShape().fill(brandOrange)
                        }
                        .opacity(fillOpacity)

                        // 3. Gold Light Sweep
                        ZStack {
                            TrainLogoTextShape()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.8), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            DumbbellShape()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.8), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .mask(
                            Rectangle()
                                .offset(x: shimmerOffset * 300)
                                .rotationEffect(.degrees(35))
                        )
                        .opacity(fillOpacity > 0.5 ? 1 : 0)
                    }
                    .frame(width: 300, height: 150)
                }
            )
            .onAppear {
                runLaunchSequence()
            }
    }

    private func runLaunchSequence() {
        // Step 1: Draw Outlines (0.0 to 1.5s)
        withAnimation(.easeInOut(duration: 1.5)) {
            trimValue = 1.0
        }

        // Step 2: Fill Colors (1.2s to 2.0s)
        withAnimation(.easeIn(duration: 0.8).delay(1.2)) {
            fillOpacity = 1.0
        }

        // Step 3: Single Brilliant Shimmer (2.0s to 3.2s)
        withAnimation(.linear(duration: 1.2).delay(2.0)) {
            shimmerOffset = 1.2
        }
    }
}

// MARK: - Precise Path Data from SVG

struct DumbbellShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Wave Bar - Points from SVG
        path.move(to: CGPoint(x: 81.1, y: 54.7))
        path.addCurve(to: CGPoint(x: 165.8, y: 54.2), control1: CGPoint(x: 109.1, y: 66.8), control2: CGPoint(x: 137.1, y: 60.6))
        path.addCurve(to: CGPoint(x: 251.7, y: 29.8), control1: CGPoint(x: 195.7, y: 47.9), control2: CGPoint(x: 223.7, y: 41.3))

        // Weights/Plates
        path.addRoundedRect(in: CGRect(x: 15.7, y: 17.5, width: 24, height: 50), cornerSize: CGSize(width: 3, height: 3))
        path.addRoundedRect(in: CGRect(x: 48.4, y: 3.5, width: 24, height: 78), cornerSize: CGSize(width: 3, height: 3))
        path.addRoundedRect(in: CGRect(x: 260.3, y: 3.5, width: 24, height: 78), cornerSize: CGSize(width: 3, height: 3))
        path.addRoundedRect(in: CGRect(x: 292.9, y: 17.5, width: 24, height: 50), cornerSize: CGSize(width: 3, height: 3))

        return path.applying(CGAffineTransform(scaleX: rect.width / 317, y: rect.height / 242))
    }
}

struct TrainLogoTextShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Path logic for 't', 'r', 'a', 'i', 'n'
        // 't'
        path.move(to: CGPoint(x: 37.25, y: 173.2))
        path.addCurve(to: CGPoint(x: 14.3, y: 150.5), control1: CGPoint(x: 30.0, y: 173.2), control2: CGPoint(x: 14.3, y: 157.4))
        path.addLine(to: CGPoint(x: 14.3, y: 76.6))
        path.addLine(to: CGPoint(x: 38.0, y: 76.6))

        // 'r'
        path.move(to: CGPoint(x: 58.6, y: 173.2))
        path.addLine(to: CGPoint(x: 58.6, y: 118.4))
        path.addCurve(to: CGPoint(x: 81.5, y: 95.7), control1: CGPoint(x: 58.6, y: 111.4), control2: CGPoint(x: 68.7, y: 95.7))

        // 'a' circle
        path.addEllipse(in: CGRect(x: 106.3, y: 95.7, width: 88.4, height: 77.5))

        // 'i'
        path.move(to: CGPoint(x: 195.8, y: 173.2))
        path.addLine(to: CGPoint(x: 195.8, y: 95.5))
        path.addEllipse(in: CGRect(x: 195.8, y: 60.0, width: 12, height: 12))

        // 'n'
        path.move(to: CGPoint(x: 229.1, y: 173.2))
        path.addLine(to: CGPoint(x: 229.1, y: 128.5))
        path.addCurve(to: CGPoint(x: 315.0, y: 128.5), control1: CGPoint(x: 229.1, y: 95.5), control2: CGPoint(x: 315.0, y: 95.5))
        path.addLine(to: CGPoint(x: 315.0, y: 173.2))

        return path.applying(CGAffineTransform(scaleX: rect.width / 317, y: rect.height / 242))
    }
}

#Preview {
    LaunchScreenView()
}