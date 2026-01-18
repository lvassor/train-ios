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
                ZStack {
                        // 1. Outline Layer (Drawing)
                        TrainLogoTextShape()
                            .trim(from: 0, to: trimValue)
                            .stroke(Color.white, lineWidth: 2)

                        DumbbellShape()
                            .trim(from: 0, to: trimValue)
                            .stroke(brandOrange, lineWidth: 2)

                        DumbbellDisksShape()
                            .trim(from: 0, to: trimValue)
                            .stroke(Color.white, lineWidth: 2)

                        // 2. Solid Fill Layer
                        Group {
                            TrainLogoTextShape().fill(Color.white, style: FillStyle(eoFill: true))
                            DumbbellShape().fill(brandOrange)
                            DumbbellDisksShape().fill(Color.white)
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
                                    ),
                                    style: FillStyle(eoFill: true)
                                )
                            DumbbellShape()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.8), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            DumbbellDisksShape()
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            )
            .onAppear {
                print("🎨 [LAUNCH ANIM] LaunchScreenView.onAppear called")
                print("🎨 [LAUNCH ANIM] Initial state - trimValue: \(trimValue), fillOpacity: \(fillOpacity), shimmerOffset: \(shimmerOffset)")
                runLaunchSequence()
            }
    }

    private func runLaunchSequence() {
        print("🎨 [LAUNCH ANIM] 🎦 Starting launch animation sequence")

        // Step 1: Draw Outlines (0.0 to 1.5s)
        print("🎨 [LAUNCH ANIM] 🎨 Step 1: Starting outline drawing animation (1.5s)")
        withAnimation(.easeInOut(duration: 1.5)) {
            trimValue = 1.0
        }

        // Step 2: Fill Colors (1.2s to 2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            print("🎨 [LAUNCH ANIM] 🎨 Step 2: Starting fill animation (0.8s)")
        }
        withAnimation(.easeIn(duration: 0.8).delay(1.2)) {
            fillOpacity = 1.0
        }

        // Step 3: Single Brilliant Shimmer (2.0s to 3.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("🎨 [LAUNCH ANIM] ✨ Step 3: Starting shimmer animation (1.2s)")
        }
        withAnimation(.linear(duration: 1.2).delay(2.0)) {
            shimmerOffset = 1.2
        }

        // Final completion logging
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            print("🎨 [LAUNCH ANIM] ✅ Launch animation sequence completed")
            print("🎨 [LAUNCH ANIM] Final state - trimValue: \(trimValue), fillOpacity: \(fillOpacity), shimmerOffset: \(shimmerOffset)")
        }
    }
}

// MARK: - Precise Path Data from SVG

struct DumbbellShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Left weight plate at translate(15,17) - Orange rectangle
        let leftPlateX: CGFloat = 15.0
        let leftPlateY: CGFloat = 17.0
        path.move(to: CGPoint(x: leftPlateX + 0.769531, y: leftPlateY + 0.582031))
        path.addLine(to: CGPoint(x: leftPlateX + 24.910156, y: leftPlateY + 0.582031))
        path.addLine(to: CGPoint(x: leftPlateX + 24.910156, y: leftPlateY + 50.09375))
        path.addLine(to: CGPoint(x: leftPlateX + 0.769531, y: leftPlateY + 50.09375))
        path.closeSubpath()

        // Right weight plate at translate(289.849181,17) - Orange rectangle
        let rightPlateX: CGFloat = 289.849181
        let rightPlateY: CGFloat = 17.0
        path.move(to: CGPoint(x: rightPlateX + 25.121094, y: rightPlateY + 50.042969))
        path.addLine(to: CGPoint(x: rightPlateX + 0.980469, y: rightPlateY + 50.042969))
        path.addLine(to: CGPoint(x: rightPlateX + 0.980469, y: rightPlateY + 0.535156))
        path.addLine(to: CGPoint(x: rightPlateX + 25.121094, y: rightPlateY + 0.535156))
        path.closeSubpath()

        // Center bar at translate(78.849181,22) - Orange CURVED path with Bezier curves
        let barX: CGFloat = 78.849181
        let barY: CGFloat = 22.0
        path.move(to: CGPoint(x: barX + 84.800781, y: barY + 32.269531))
        path.addCurve(to: CGPoint(x: barX + 0.101562, y: barY + 32.757812), control1: CGPoint(x: barX + 56.140625, y: barY + 38.617188), control2: CGPoint(x: barX + 28.121094, y: barY + 44.851562))
        path.addLine(to: CGPoint(x: barX + 0.101562, y: barY + 9.5625))
        path.addCurve(to: CGPoint(x: barX + 86.089844, y: barY + 8.339844), control1: CGPoint(x: barX + 29.085938, y: barY + 21.28125), control2: CGPoint(x: barX + 58.070312, y: barY + 14.6875))
        path.addCurve(to: CGPoint(x: barX + 170.78906, y: barY + 7.851562), control1: CGPoint(x: barX + 114.75, y: barY + 1.992188), control2: CGPoint(x: barX + 142.76953, y: barY + -4.242188))
        path.addLine(to: CGPoint(x: barX + 170.78906, y: barY + 31.050781))
        path.addCurve(to: CGPoint(x: barX + 84.800781, y: barY + 32.269531), control1: CGPoint(x: barX + 141.80469, y: barY + 19.328125), control2: CGPoint(x: barX + 112.82031, y: barY + 25.921875))
        path.closeSubpath()

        // Use uniform scaling to prevent horizontal stretching
        let scale = min(rect.width / 317, rect.height / 242)
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

struct DumbbellDisksShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Left disk at translate(45.849181,3) - White rectangle
        let leftDiskX: CGFloat = 45.849181
        let leftDiskY: CGFloat = 3.0
        path.move(to: CGPoint(x: leftDiskX + 0.4375, y: leftDiskY + 0.542969))
        path.addLine(to: CGPoint(x: leftDiskX + 24.578125, y: leftDiskY + 0.542969))
        path.addLine(to: CGPoint(x: leftDiskX + 24.578125, y: leftDiskY + 78.0625))
        path.addLine(to: CGPoint(x: leftDiskX + 0.4375, y: leftDiskY + 78.0625))
        path.closeSubpath()

        // Right disk at translate(257.849181,3) - White rectangle
        let rightDiskX: CGFloat = 257.849181
        let rightDiskY: CGFloat = 3.0
        path.move(to: CGPoint(x: rightDiskX + 24.457031, y: rightDiskY + 78.078125))
        path.addLine(to: CGPoint(x: rightDiskX + 0.3125, y: rightDiskY + 78.078125))
        path.addLine(to: CGPoint(x: rightDiskX + 0.3125, y: rightDiskY + 0.558594))
        path.addLine(to: CGPoint(x: rightDiskX + 24.457031, y: rightDiskY + 0.558594))
        path.closeSubpath()

        // Use uniform scaling to prevent horizontal stretching
        let scale = min(rect.width / 317, rect.height / 242)
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

struct TrainLogoTextShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Letter "t" at translate(1.223071,173.24574)
        let tX: CGFloat = 1.223071
        let tY: CGFloat = 173.24574
        path.move(to: CGPoint(x: tX + 37.25, y: tY + 0.0))
        path.addCurve(to: CGPoint(x: tX + 20.4375, y: tY + -6.125), control1: CGPoint(x: tX + 30.082031, y: tY + 0.0), control2: CGPoint(x: tX + 24.476562, y: tY + -2.039062))
        path.addCurve(to: CGPoint(x: tX + 14.390625, y: tY + -22.71875), control1: CGPoint(x: tX + 16.40625, y: tY + -10.21875), control2: CGPoint(x: tX + 14.390625, y: tY + -15.75))
        path.addLine(to: CGPoint(x: tX + 14.390625, y: tY + -96.609375))
        path.addLine(to: CGPoint(x: tX + 38.015625, y: tY + -96.609375))
        path.addLine(to: CGPoint(x: tX + 38.015625, y: tY + -24.078125))
        path.addCurve(to: CGPoint(x: tX + 39.296875, y: tY + -20.96875), control1: CGPoint(x: tX + 38.015625, y: tY + -22.867188), control2: CGPoint(x: tX + 38.441406, y: tY + -21.832031))
        path.addCurve(to: CGPoint(x: tX + 42.40625, y: tY + -19.6875), control1: CGPoint(x: tX + 40.148438, y: tY + -20.113281), control2: CGPoint(x: tX + 41.1875, y: tY + -19.6875))
        path.addLine(to: CGPoint(x: tX + 59.359375, y: tY + -19.6875))
        path.addLine(to: CGPoint(x: tX + 59.359375, y: tY + 0.0))
        path.closeSubpath()
        path.move(to: CGPoint(x: tX + 1.671875, y: tY + -58.453125))
        path.addLine(to: CGPoint(x: tX + 1.671875, y: tY + -77.6875))
        path.addLine(to: CGPoint(x: tX + 59.359375, y: tY + -77.6875))
        path.addLine(to: CGPoint(x: tX + 59.359375, y: tY + -58.453125))
        path.closeSubpath()

        // Letter "r" at translate(58.61144,173.24574)
        let rX: CGFloat = 58.61144
        let rY: CGFloat = 173.24574
        path.move(to: CGPoint(x: rX + 8.171875, y: rY + 0.0))
        path.addLine(to: CGPoint(x: rX + 8.171875, y: rY + -54.828125))
        path.addCurve(to: CGPoint(x: rX + 14.234375, y: rY + -71.46875), control1: CGPoint(x: rX + 8.171875, y: rY + -61.890625), control2: CGPoint(x: rX + 10.191406, y: rY + -67.4375))
        path.addCurve(to: CGPoint(x: rX + 31.046875, y: rY + -77.53125), control1: CGPoint(x: rX + 18.273438, y: rY + -75.507812), control2: CGPoint(x: rX + 23.878906, y: rY + -77.53125))
        path.addLine(to: CGPoint(x: rX + 53.609375, y: rY + -77.53125))
        path.addLine(to: CGPoint(x: rX + 53.609375, y: rY + -58.453125))
        path.addLine(to: CGPoint(x: rX + 36.796875, y: rY + -58.453125))
        path.addCurve(to: CGPoint(x: rX + 33.15625, y: rY + -57.015625), control1: CGPoint(x: rX + 35.378906, y: rY + -58.453125), control2: CGPoint(x: rX + 34.164062, y: rY + -57.972656))
        path.addCurve(to: CGPoint(x: rX + 31.65625, y: rY + -53.3125), control1: CGPoint(x: rX + 32.15625, y: rY + -56.054688), control2: CGPoint(x: rX + 31.65625, y: rY + -54.820312))
        path.addLine(to: CGPoint(x: rX + 31.65625, y: rY + 0.0))
        path.closeSubpath()

        // Letter "a" at translate(106.30878,173.24574) - EXACT SVG PATH including hole
        let aX: CGFloat = 106.30878
        let aY: CGFloat = 173.24574
        path.move(to: CGPoint(x: aX + 39.984375, y: aY + 1.8125))
        path.addCurve(to: CGPoint(x: aX + 21.8125, y: aY + -3.484375), control1: CGPoint(x: aX + 33.117188, y: aY + 1.8125), control2: CGPoint(x: aX + 27.0625, y: aY + 0.046875))
        path.addCurve(to: CGPoint(x: aX + 9.546875, y: aY + -17.78125), control1: CGPoint(x: aX + 16.5625, y: aY + -7.015625), control2: CGPoint(x: aX + 12.472656, y: aY + -11.78125))
        path.addCurve(to: CGPoint(x: aX + 5.15625, y: aY + -38.15625), control1: CGPoint(x: aX + 6.617188, y: aY + -23.789062), control2: CGPoint(x: aX + 5.15625, y: aY + -30.582031))
        path.addCurve(to: CGPoint(x: aX + 10.296875, y: aY + -59.28125), control1: CGPoint(x: aX + 5.15625, y: aY + -46.03125), control2: CGPoint(x: aX + 6.867188, y: aY + -53.070312))
        path.addCurve(to: CGPoint(x: aX + 24.90625, y: aY + -74.046875), control1: CGPoint(x: aX + 13.734375, y: aY + -65.488281), control2: CGPoint(x: aX + 18.601562, y: aY + -70.410156))
        path.addCurve(to: CGPoint(x: aX + 47.25, y: aY + -79.5), control1: CGPoint(x: aX + 31.21875, y: aY + -77.679688), control2: CGPoint(x: aX + 38.664062, y: aY + -79.5))
        path.addCurve(to: CGPoint(x: aX + 69.421875, y: aY + -74.125), control1: CGPoint(x: aX + 55.925781, y: aY + -79.5), control2: CGPoint(x: aX + 63.316406, y: aY + -77.707031))
        path.addCurve(to: CGPoint(x: aX + 83.515625, y: aY + -59.4375), control1: CGPoint(x: aX + 75.535156, y: aY + -70.539062), control2: CGPoint(x: aX + 80.234375, y: aY + -65.644531))
        path.addCurve(to: CGPoint(x: aX + 88.4375, y: aY + -38.609375), control1: CGPoint(x: aX + 86.796875, y: aY + -53.226562), control2: CGPoint(x: aX + 88.4375, y: aY + -46.285156))
        path.addLine(to: CGPoint(x: aX + 88.4375, y: aY + 0.0))
        path.addLine(to: CGPoint(x: aX + 65.421875, y: aY + 0.0))
        path.addLine(to: CGPoint(x: aX + 65.421875, y: aY + -12.421875))
        path.addLine(to: CGPoint(x: aX + 64.8125, y: aY + -12.421875))
        path.addCurve(to: CGPoint(x: aX + 59.359375, y: aY + -5.0625), control1: CGPoint(x: aX + 63.394531, y: aY + -9.691406), control2: CGPoint(x: aX + 61.578125, y: aY + -7.238281))
        path.addCurve(to: CGPoint(x: aX + 51.25, y: aY + 0.0), control1: CGPoint(x: aX + 57.140625, y: aY + -2.894531), control2: CGPoint(x: aX + 54.4375, y: aY + -1.207031))
        path.addCurve(to: CGPoint(x: aX + 39.984375, y: aY + 1.8125), control1: CGPoint(x: aX + 48.070312, y: aY + 1.207031), control2: CGPoint(x: aX + 44.316406, y: aY + 1.8125))
        path.closeSubpath()
        // Inner hole (centered with outer shape, clockwise winding to cut out)
        // Outer shape center: 46.796875, Original hole center: 6.8125
        // Shift all x-coordinates by: 39.984375, reverse direction for hole
        path.move(to: CGPoint(x: aX + 46.953125, y: aY + -20.28125))
        path.addCurve(to: CGPoint(x: aX + 37.40625, y: aY + -22.9375), control1: CGPoint(x: aX + 43.316406, y: aY + -20.28125), control2: CGPoint(x: aX + 40.132812, y: aY + -21.164062))
        path.addCurve(to: CGPoint(x: aX + 31.1875, y: aY + -30.28125), control1: CGPoint(x: aX + 34.675781, y: aY + -24.707031), control2: CGPoint(x: aX + 32.601562, y: aY + -27.15625))
        path.addCurve(to: CGPoint(x: aX + 29.078125, y: aY + -40.734375), control1: CGPoint(x: aX + 29.781250, y: aY + -33.414062), control2: CGPoint(x: aX + 29.078125, y: aY + -36.898438))
        path.addCurve(to: CGPoint(x: aX + 31.1875, y: aY + -50.875), control1: CGPoint(x: aX + 29.078125, y: aY + -44.460938), control2: CGPoint(x: aX + 29.781250, y: aY + -47.84375))
        path.addCurve(to: CGPoint(x: aX + 37.40625, y: aY + -58.0625), control1: CGPoint(x: aX + 32.601562, y: aY + -53.90625), control2: CGPoint(x: aX + 34.675781, y: aY + -56.300781))
        path.addCurve(to: CGPoint(x: aX + 46.953125, y: aY + -60.71875), control1: CGPoint(x: aX + 40.132812, y: aY + -59.832031), control2: CGPoint(x: aX + 43.316406, y: aY + -60.71875))
        path.addCurve(to: CGPoint(x: aX + 56.25, y: aY + -58.0625), control1: CGPoint(x: aX + 50.484375, y: aY + -60.71875), control2: CGPoint(x: aX + 53.582031, y: aY + -59.832031))
        path.addCurve(to: CGPoint(x: aX + 62.390625, y: aY + -50.875), control1: CGPoint(x: aX + 58.925781, y: aY + -56.300781), control2: CGPoint(x: aX + 60.972656, y: aY + -53.90625))
        path.addCurve(to: CGPoint(x: aX + 64.515625, y: aY + -40.734375), control1: CGPoint(x: aX + 63.804688, y: aY + -47.84375), control2: CGPoint(x: aX + 64.515625, y: aY + -44.460938))
        path.addCurve(to: CGPoint(x: aX + 62.390625, y: aY + -30.28125), control1: CGPoint(x: aX + 64.515625, y: aY + -36.898438), control2: CGPoint(x: aX + 63.804688, y: aY + -33.414062))
        path.addCurve(to: CGPoint(x: aX + 56.25, y: aY + -22.9375), control1: CGPoint(x: aX + 60.972656, y: aY + -27.15625), control2: CGPoint(x: aX + 58.925781, y: aY + -24.707031))
        path.addCurve(to: CGPoint(x: aX + 46.953125, y: aY + -20.28125), control1: CGPoint(x: aX + 53.582031, y: aY + -21.164062), control2: CGPoint(x: aX + 50.484375, y: aY + -20.28125))
        path.closeSubpath()

        // Letter "i" at translate(195.79868,173.24574)
        let iX: CGFloat = 195.79868
        let iY: CGFloat = 173.24574
        // Body of "i" (unchanged)
        path.move(to: CGPoint(x: iX + 8.78125, y: iY + 0.0))
        path.addLine(to: CGPoint(x: iX + 8.78125, y: iY + -77.6875))
        path.addLine(to: CGPoint(x: iX + 32.40625, y: iY + -77.6875))
        path.addLine(to: CGPoint(x: iX + 32.40625, y: iY + 0.0))
        path.closeSubpath()
        // Dot of "i" (properly aligned with body dimensions)
        // Body width: 32.40625 - 8.78125 = 23.625
        // Create circular dot with same width as body, centered above it
        let dotRadius: CGFloat = 23.625 / 2  // Half the body width
        let dotCenterX: CGFloat = 8.78125 + dotRadius  // Center horizontally with body
        let dotCenterY: CGFloat = -100.328125  // Center Y coordinate from original

        // Create circle using 4 Bezier curves (standard circle construction)
        let controlOffset: CGFloat = dotRadius * 0.552284749831  // Circle control point offset

        // Start at top of circle
        path.move(to: CGPoint(x: iX + dotCenterX, y: iY + dotCenterY - dotRadius))
        // Top-right curve
        path.addCurve(to: CGPoint(x: iX + dotCenterX + dotRadius, y: iY + dotCenterY),
                      control1: CGPoint(x: iX + dotCenterX + controlOffset, y: iY + dotCenterY - dotRadius),
                      control2: CGPoint(x: iX + dotCenterX + dotRadius, y: iY + dotCenterY - controlOffset))
        // Right-bottom curve
        path.addCurve(to: CGPoint(x: iX + dotCenterX, y: iY + dotCenterY + dotRadius),
                      control1: CGPoint(x: iX + dotCenterX + dotRadius, y: iY + dotCenterY + controlOffset),
                      control2: CGPoint(x: iX + dotCenterX + controlOffset, y: iY + dotCenterY + dotRadius))
        // Bottom-left curve
        path.addCurve(to: CGPoint(x: iX + dotCenterX - dotRadius, y: iY + dotCenterY),
                      control1: CGPoint(x: iX + dotCenterX - controlOffset, y: iY + dotCenterY + dotRadius),
                      control2: CGPoint(x: iX + dotCenterX - dotRadius, y: iY + dotCenterY + controlOffset))
        // Left-top curve
        path.addCurve(to: CGPoint(x: iX + dotCenterX, y: iY + dotCenterY - dotRadius),
                      control1: CGPoint(x: iX + dotCenterX - dotRadius, y: iY + dotCenterY - controlOffset),
                      control2: CGPoint(x: iX + dotCenterX - controlOffset, y: iY + dotCenterY - dotRadius))
        path.closeSubpath()

        // Letter "n" at translate(229.1109,173.24574)
        let nX: CGFloat = 229.1109
        let nY: CGFloat = 173.24574
        path.move(to: CGPoint(x: nX + 8.78125, y: nY + 0.0))
        path.addLine(to: CGPoint(x: nX + 8.78125, y: nY + -44.671875))
        path.addCurve(to: CGPoint(x: nX + 13.46875, y: nY + -62.234375), control1: CGPoint(x: nX + 8.78125, y: nY + -51.128906), control2: CGPoint(x: nX + 10.34375, y: nY + -56.984375))
        path.addCurve(to: CGPoint(x: nX + 26.875, y: nY + -74.796875), control1: CGPoint(x: nX + 16.601562, y: nY + -67.484375), control2: CGPoint(x: nX + 21.070312, y: nY + -71.671875))
        path.addCurve(to: CGPoint(x: nX + 47.546875, y: nY + -79.5), control1: CGPoint(x: nX + 32.6875, y: nY + -77.929688), control2: CGPoint(x: nX + 39.578125, y: nY + -79.5))
        path.addCurve(to: CGPoint(x: nX + 68.21875, y: nY + -74.796875), control1: CGPoint(x: nX + 55.628906, y: nY + -79.5), control2: CGPoint(x: nX + 62.519531, y: nY + -77.929688))
        path.addCurve(to: CGPoint(x: nX + 81.3125, y: nY + -62.234375), control1: CGPoint(x: nX + 73.925781, y: nY + -71.671875), control2: CGPoint(x: nX + 78.289062, y: nY + -67.484375))
        path.addCurve(to: CGPoint(x: nX + 85.859375, y: nY + -44.671875), control1: CGPoint(x: nX + 84.34375, y: nY + -56.984375), control2: CGPoint(x: nX + 85.859375, y: nY + -51.128906))
        path.addLine(to: CGPoint(x: nX + 85.859375, y: nY + 0.0))
        path.addLine(to: CGPoint(x: nX + 62.390625, y: nY + 0.0))
        path.addLine(to: CGPoint(x: nX + 62.390625, y: nY + -44.0625))
        path.addCurve(to: CGPoint(x: nX + 60.421875, y: nY + -51.5625), control1: CGPoint(x: nX + 62.390625, y: nY + -46.789062), control2: CGPoint(x: nX + 61.734375, y: nY + -49.289062))
        path.addCurve(to: CGPoint(x: nX + 55.046875, y: nY + -57.015625), control1: CGPoint(x: nX + 59.109375, y: nY + -53.832031), control2: CGPoint(x: nX + 57.316406, y: nY + -55.648438))
        path.addCurve(to: CGPoint(x: nX + 47.40625, y: nY + -59.0625), control1: CGPoint(x: nX + 52.773438, y: nY + -58.378906), control2: CGPoint(x: nX + 50.226562, y: nY + -59.0625))
        path.addCurve(to: CGPoint(x: nX + 39.59375, y: nY + -57.015625), control1: CGPoint(x: nX + 44.476562, y: nY + -59.0625), control2: CGPoint(x: nX + 41.875, y: nY + -58.378906))
        path.addCurve(to: CGPoint(x: nX + 34.21875, y: nY + -51.5625), control1: CGPoint(x: nX + 37.320312, y: nY + -55.648438), control2: CGPoint(x: nX + 35.53125, y: nY + -53.832031))
        path.addCurve(to: CGPoint(x: nX + 32.25, y: nY + -44.0625), control1: CGPoint(x: nX + 32.90625, y: nY + -49.289062), control2: CGPoint(x: nX + 32.25, y: nY + -46.789062))
        path.addLine(to: CGPoint(x: nX + 32.25, y: nY + 0.0))
        path.closeSubpath()

        // Use uniform scaling to prevent horizontal stretching
        let scale = min(rect.width / 317, rect.height / 242)
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

#Preview {
    LaunchScreenView()
}