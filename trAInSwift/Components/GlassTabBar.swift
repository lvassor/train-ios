//
//  GlassTabBar.swift
//  trAInSwift
//
//  Sophisticated sliding lens tab bar that replicates Apple's Phone app interaction
//  Uses Metal shaders for TRUE optical glass refraction effect
//
//  KEY MECHANISM:
//  The shader uses layer.sample(position + offset) to read pixels from displaced
//  locations, creating genuine optical warping - not just masking/opacity changes.
//
//  LAYER STRUCTURE:
//  - Single combined layer with both grey (outside lens) and accent (inside lens) icons
//  - Shader applies displacement to create refraction effect
//  - Pixels inside lens are sampled from offset positions, creating magnification/warp
//

import SwiftUI

// MARK: - Tab Item Model

struct GlassTabItem<Tab: Hashable>: Identifiable {
    let id: Tab
    let icon: String
    let label: String
}

// MARK: - Glass Tab Bar with Metal Shader Refraction

struct GlassTabBar<Tab: Hashable>: View {
    @Binding var selectedTab: Tab
    let tabs: [GlassTabItem<Tab>]
    var accentColor: Color = .trainPrimary
    var inactiveColor: Color = .white.opacity(0.5)
    var showLabels: Bool = false
    var lensInset: CGFloat = 0.1
    var onTabSelected: ((Tab) -> Void)?

    // Animation & gesture state
    @State private var lensOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @GestureState private var dragOffset: CGFloat = 0

    // Layout constants
    private let itemHeight: CGFloat = 44
    private let lensHorizontalPadding: CGFloat = 6
    private let lensVerticalPadding: CGFloat = 4
    private let iconSize: CGFloat = 22
    private let labelSize: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let totalHeight = geometry.size.height
            let itemWidth = totalWidth / CGFloat(tabs.count)
            let lensWidth = itemWidth * (1.0 - lensInset * 2) + lensHorizontalPadding * 2
            let lensHeight = itemHeight + lensVerticalPadding * 2
            let currentPosition = currentLensCenter(itemWidth: itemWidth)

            ZStack {
                // LAYER 1: Background accent icons (revealed through refraction)
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        tabIconView(tab: tab, color: accentColor)
                            .frame(width: itemWidth, height: itemHeight)
                    }
                }

                // LAYER 2: Foreground grey icons with refraction shader
                // The shader makes pixels inside the lens sample from displaced positions
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        tabIconView(tab: tab, color: inactiveColor)
                            .frame(width: itemWidth, height: itemHeight)
                    }
                }
                .layerEffect(
                    ShaderLibrary.glassLensPunchthrough(
                        .float2(totalWidth, totalHeight),
                        .float2(currentPosition.x, currentPosition.y),
                        .float2(lensWidth, lensHeight),
                        .float(1.25),                         // magnification - 25% magnification at center
                        .float(0.03),                         // chromaticStrength - subtle rainbow fringing
                        .float(3.0),                          // edgeSoftness - pixels of soft edge transition
                        .float(isDragging ? 1.0 : 0.0)        // isActive
                    ),
                    maxSampleOffset: CGSize(width: 50, height: 50)
                )

                // LAYER 3: Lens outline with glass rim effect
                lensOutlineView(width: lensWidth, height: lensHeight)
                    .position(currentPosition)

                // LAYER 4: Touch targets
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        Color.clear
                            .frame(width: itemWidth, height: itemHeight)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectTab(tab.id, itemWidth: itemWidth)
                            }
                    }
                }

                // LAYER 5: Drag handle
                Color.clear
                    .frame(width: lensWidth + 20, height: lensHeight + 10)
                    .contentShape(Capsule())
                    .position(currentPosition)
                    .gesture(lensDragGesture(itemWidth: itemWidth, totalWidth: totalWidth))
            }
            .onAppear {
                initializeLensPosition(itemWidth: itemWidth)
            }
            .onChange(of: selectedTab) { _, newValue in
                updateLensForSelection(itemWidth: itemWidth)
            }
        }
        .frame(height: itemHeight + lensVerticalPadding * 2)
    }

    // MARK: - Tab Icon View

    @ViewBuilder
    private func tabIconView(tab: GlassTabItem<Tab>, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: tab.icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(color)

            if showLabels {
                Text(tab.label)
                    .font(.system(size: labelSize, weight: .medium))
                    .foregroundColor(color)
            }
        }
    }

    // MARK: - Lens Outline View

    @ViewBuilder
    private func lensOutlineView(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Inner glow
            Capsule()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(isDragging ? 0.5 : 0.35), location: 0.0),
                            .init(color: .white.opacity(isDragging ? 0.2 : 0.1), location: 0.25),
                            .init(color: .white.opacity(0.05), location: 0.5),
                            .init(color: .white.opacity(isDragging ? 0.2 : 0.1), location: 0.75),
                            .init(color: .white.opacity(isDragging ? 0.5 : 0.35), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
                .frame(width: width - 2, height: height - 2)
                .blur(radius: 0.5)

            // Main outline
            Capsule()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(isDragging ? 0.4 : 0.3), location: 0.0),
                            .init(color: .white.opacity(isDragging ? 0.15 : 0.08), location: 0.3),
                            .init(color: .white.opacity(isDragging ? 0.15 : 0.08), location: 0.7),
                            .init(color: .white.opacity(isDragging ? 0.4 : 0.3), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: width, height: height)
        }
        .shadow(color: .black.opacity(0.25), radius: isDragging ? 8 : 4, x: 0, y: 2)
    }

    // MARK: - Gesture Handling

    private func lensDragGesture(itemWidth: CGFloat, totalWidth: CGFloat) -> some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width
            }
            .onChanged { _ in
                withAnimation(.easeOut(duration: 0.08)) {
                    isDragging = true
                }
            }
            .onEnded { value in
                let predictedEndOffset = lensOffset + value.translation.width + value.predictedEndTranslation.width * 0.25
                let nearestIndex = nearestTabIndex(for: predictedEndOffset, itemWidth: itemWidth)
                let newTab = tabs[nearestIndex].id

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    lensOffset = CGFloat(nearestIndex) * itemWidth
                    selectedTab = newTab
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        isDragging = false
                    }
                }

                onTabSelected?(newTab)
            }
    }

    // MARK: - Position Calculations

    private func currentLensCenter(itemWidth: CGFloat) -> CGPoint {
        let xPosition = lensOffset + dragOffset + itemWidth / 2
        return CGPoint(x: xPosition, y: (itemHeight + lensVerticalPadding * 2) / 2)
    }

    private func initializeLensPosition(itemWidth: CGFloat) {
        if let index = tabs.firstIndex(where: { $0.id == selectedTab }) {
            lensOffset = CGFloat(index) * itemWidth
        }
    }

    private func updateLensForSelection(itemWidth: CGFloat) {
        if let index = tabs.firstIndex(where: { $0.id == selectedTab }) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                lensOffset = CGFloat(index) * itemWidth
            }
        }
    }

    private func selectTab(_ tab: Tab, itemWidth: CGFloat) {
        guard let index = tabs.firstIndex(where: { $0.id == tab }) else { return }

        withAnimation(.easeOut(duration: 0.1)) {
            isDragging = true
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedTab = tab
            lensOffset = CGFloat(index) * itemWidth
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.2)) {
                isDragging = false
            }
        }

        onTabSelected?(tab)
    }

    private func nearestTabIndex(for offset: CGFloat, itemWidth: CGFloat) -> Int {
        let index = Int(round(offset / itemWidth))
        return max(0, min(tabs.count - 1, index))
    }
}

// MARK: - Convenience Initializer for ToolbarTab

extension GlassTabBar where Tab == ToolbarTab {
    init(
        selectedTab: Binding<ToolbarTab>,
        excludeAccount: Bool = true,
        accentColor: Color = .trainPrimary,
        onTabSelected: ((ToolbarTab) -> Void)? = nil
    ) {
        self._selectedTab = selectedTab
        self.accentColor = accentColor

        let allTabs = ToolbarTab.allCases
        self.tabs = (excludeAccount ? allTabs.filter { $0 != .account } : allTabs).map { tab in
            GlassTabItem(id: tab, icon: tab.icon, label: tab.title)
        }
        self.onTabSelected = onTabSelected
    }
}

// MARK: - Logger Tab Enum (for ExerciseLoggerView)

enum LoggerTabOption: String, CaseIterable, Hashable {
    case logger = "Logger"
    case demo = "Demo"

    var icon: String {
        switch self {
        case .logger: return "list.bullet.clipboard"
        case .demo: return "play.circle.fill"
        }
    }
}

// MARK: - Library Tab Enum (for CombinedLibraryView)

enum LibraryTabOption: String, CaseIterable, Hashable {
    case exercises = "Exercises"
    case education = "Education"

    var icon: String {
        switch self {
        case .exercises: return "dumbbell.fill"
        case .education: return "book.fill"
        }
    }
}

// MARK: - Preview

#Preview("Glass Tab Bar - Dashboard") {
    struct PreviewWrapper: View {
        @State private var selectedTab: ToolbarTab = .dashboard

        var body: some View {
            ZStack {
                AppGradient.background
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    Text("Selected: \(selectedTab.title)")
                        .foregroundColor(.white)
                        .font(.headline)

                    Spacer()

                    GlassTabBar(
                        selectedTab: $selectedTab,
                        onTabSelected: { tab in
                            print("Selected: \(tab.title)")
                        }
                    )
                    .frame(width: 200)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.bottom, 40)
                }
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Glass Tab Bar - Library Toggle") {
    struct PreviewWrapper: View {
        @State private var selectedTab: LibraryTabOption = .exercises

        var body: some View {
            ZStack {
                AppGradient.background
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    Text("Library: \(selectedTab.rawValue)")
                        .foregroundColor(.white)
                        .font(.headline)

                    Spacer()

                    GlassTabBar(
                        selectedTab: $selectedTab,
                        tabs: LibraryTabOption.allCases.map { tab in
                            GlassTabItem(id: tab, icon: tab.icon, label: tab.rawValue)
                        },
                        showLabels: true,
                        lensInset: 0.15
                    )
                    .frame(width: 180)
                    .padding(6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.bottom, 40)
                }
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Glass Tab Bar - Logger Toggle") {
    struct PreviewWrapper: View {
        @State private var selectedTab: LoggerTabOption = .logger

        var body: some View {
            ZStack {
                AppGradient.background
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    Text("Tab: \(selectedTab.rawValue)")
                        .foregroundColor(.white)
                        .font(.headline)

                    Spacer()

                    GlassTabBar(
                        selectedTab: $selectedTab,
                        tabs: LoggerTabOption.allCases.map { tab in
                            GlassTabItem(id: tab, icon: tab.icon, label: tab.rawValue)
                        },
                        showLabels: true,
                        lensInset: 0.12
                    )
                    .frame(width: 170)
                    .padding(5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.bottom, 40)
                }
            }
        }
    }

    return PreviewWrapper()
}
