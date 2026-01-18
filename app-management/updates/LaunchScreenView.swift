import SwiftUI

struct LaunchScreenView: View {
    @State private var trimValue: CGFloat = 0.0
    @State private var fillOpacity: Double = 0.0
    @State private var shimmerOffset: CGFloat = -1.2
    @State private var isReadyToProceed = false
    
    // Brand Colors from SVG
    let brandOrange = Color(red: 0.941, green: 0.667, blue: 0.243) // #f0aa3e

    var body: some View {
        ZStack {
            if isReadyToProceed {
                WelcomeView(onContinue: {}, onLogin: {}) 
                    .transition(.opacity)
            } else {
                Color.black.ignoresSafeArea()
                
                VStack {
                    ZStack {
                        // 1. Text Outline (White)
                        TrainTextShape()
                            .trim(from: 0, to: trimValue)
                            .stroke(Color.white, lineWidth: 2)
                        
                        // 2. Dumbbell Outline (Orange)
                        DumbbellShape()
                            .trim(from: 0, to: trimValue)
                            .stroke(brandOrange, lineWidth: 2)

                        // 3. Fills
                        Group {
                            TrainTextShape().fill(Color.white)
                            DumbbellShape().fill(brandOrange)
                        }
                        .opacity(fillOpacity)
                        
                        // 4. Gold Shimmer Mask
                        Group {
                            TrainTextShape()
                            DumbbellShape()
                        }
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.8), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .mask(
                            Rectangle()
                                .offset(x: shimmerOffset * 300)
                                .rotationEffect(.degrees(35))
                        )
                        .opacity(fillOpacity > 0.5 ? 1 : 0)
                    }
                    .frame(width: 317, height: 242) // Match SVG viewport 
                }
                .onAppear(perform: runLaunchSequence)
            }
        }
    }

    private func runLaunchSequence() {
        withAnimation(.easeInOut(duration: 1.8)) { trimValue = 1.0 }
        withAnimation(.easeIn(duration: 0.6).delay(1.6)) { fillOpacity = 1.0 }
        withAnimation(.linear(duration: 1.5).delay(2.2)) { shimmerOffset = 1.2 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation { isReadyToProceed = true }
        }
    }
}

// MARK: - PLACEHOLDER SHAPES
// Python script will replace the TODOs below with real coordinates 

struct TrainTextShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // TODO: ADD_TEXT_PATHS_HERE
        return path.applying(CGAffineTransform(scaleX: rect.width / 317, y: rect.height / 242))
    }
}

struct DumbbellShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // TODO: ADD_DUMBBELL_PATHS_HERE
        return path.applying(CGAffineTransform(scaleX: rect.width / 317, y: rect.height / 242))
    }
}