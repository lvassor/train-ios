Ok we need to make some design changes. These changes relate directly to the what the user experiences when they click on an exercise inside of their workout. This opens the exercise logger, with the choice of navigating to the demo tab, and history tab. the changes in this document relate explicitly to these 3 sections. In order to detail the changes I desire, I will go through each section, describe the current design and then provde code for the target design that claude has derived from figma. however, note that code has directly converted from designs that contain variable strings for example. so i have left comments in the code to signify where hard coded strings are in fact variable. I walk through the state from the top of the screen to the bottom of the screen. In this section I address the history page.

# 1. Logger Page
## Current State
1. Exercise title as a string, centre-aligned
2. Rounded corner container containing Back button and left chevrow on the left hand side. On the the right hand side, "Exercise X/5" where X is the number of exercises within the current active workout that have been submitted. This corresponds to the progress of the progress bar.
3. Orange progress bar which sits flush with the bottom border of the container above (point 1.). Progress bar progresses in line with the number of exercises submitted in the active workout thus far.
4. Pill toolbar allowing quick navigation between Logger, Demo and History pages using native glass slider design.
5. Below the toolbar are two containers, side-by-side. The left container is white and larger and child elements include title "Best Set". The right container is smaller and child elements are "Start Weight" with weight in kg.
6. Beneath these is a new, larger container, child elements: graph display visual of exercise history, title "Progress" and tool bar to switch view between Total Volume and Max Weight.
7. Below this we have the Submit Exercise button in grey, this becomes illuminated in accent colour only when all sets have been marked as complete.
8. Beneath this is the main toolbar allow the user to navigate to home, milestones, library of their account settings.

## Target State
This code has the correct text colours for the app's light mode. However, in dark mode you need to interpret these intelligently where black colours become white. You should also retain the nice apple style gradient we have behind the Submit Exercise button (which becomes "Complete Exercise") for any scrollable content that goes behind this CTA button.
```swift
import SwiftUI
import Charts

struct HistoryTabView: View {
    @State private var selectedTab = 2 // History selected
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight: .medium))
                    }
                    Spacer()
                    Text("Full Body")
                        .font(.system(size: 18, weight: .medium))
                    Spacer()
                    Text("1/5")
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                
                // Tab Selector
                TabSelector(selectedTab: $selectedTab)
                    .padding(.top, 16)
                
                // Exercise Info
                ExerciseHeader()
                    .padding(.top, 20)
                
                // Stats Cards
                HStack(spacing: 20) {
                    StatCard(title: "Best Set", value: "X kg • X reps")
                    StatCard(title: "Start Weight", value: "X kg")
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                
                // Progress Chart
                ProgressChart()
                    .frame(height: 180)
                    .padding(.top, 8)
                
                // History Entries
                VStack(spacing: 20) {
                    ForEach(sampleHistory) { entry in
                        HistoryCard(entry: entry)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top: 24)
                .padding(.bottom, 100)
            }
        }
        .background(Color.white)
    }
    
    private var sampleHistory: [HistoryEntry] {
        [
            HistoryEntry(date: "XX/XX/XX", sets: [
                SetData(number: 1, weight: "12kg", reps: "12", isHighlighted: true),
                SetData(number: 2, weight: "X kg", reps: "X", isHighlighted: false),
                SetData(number: 3, weight: "X kg", reps: "X", isHighlighted: false)
            ], hasBadge: true),
            HistoryEntry(date: "XX/XX/XX", sets: [
                SetData(number: 1, weight: "12kg", reps: "12", isHighlighted: true),
                SetData(number: 2, weight: "X kg", reps: "X", isHighlighted: false),
                SetData(number: 3, weight: "X kg", reps: "X", isHighlighted: false)
            ], hasBadge: true),
            HistoryEntry(date: "XX/XX/XX", sets: [
                SetData(number: 1, weight: "12kg", reps: "12", isHighlighted: true),
                SetData(number: 2, weight: "X kg", reps: "X", isHighlighted: false),
                SetData(number: 3, weight: "X kg", reps: "X", isHighlighted: false)
            ], hasBadge: true)
        ]
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .light))
            Text(value)
                .font(.system(size: 16, weight: .medium))
        }
        .frame(width: 160, height: 60)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}

// MARK: - Progress Chart
struct ProgressChart: View {
    private let dataPoints: [ChartPoint] = [
        ChartPoint(x: 0, y: 0.3),
        ChartPoint(x: 1, y: 0.5),
        ChartPoint(x: 2, y: 0.35),
        ChartPoint(x: 3, y: 0.6),
        ChartPoint(x: 4, y: 0.45),
        ChartPoint(x: 5, y: 0.7),
        ChartPoint(x: 6, y: 0.55),
        ChartPoint(x: 7, y: 0.8)
    ]
    
    var body: some View {
        Chart {
            ForEach(dataPoints) { point in
                AreaMark(
                    x: .value("Week", point.x),
                    y: .value("Progress", point.y)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LineMark(
                    x: .value("Week", point.x),
                    y: .value("Progress", point.y)
                )
                .foregroundStyle(Color.black)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            
            // Current point indicator
            PointMark(
                x: .value("Week", 5),
                y: .value("Progress", 0.7)
            )
            .foregroundStyle(Color.black)
            .symbolSize(100)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .padding(.horizontal, 18)
    }
}

struct ChartPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
}

// MARK: - History Card
struct HistoryCard: View {
    let entry: HistoryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 0) {
                    Text(entry.date)
                        .font(.system(size: 16, weight: .medium))
                    Text(" - date")
                        .font(.system(size: 16, weight: .light))
                }
                Spacer()
                if entry.hasBadge {
                    Image(systemName: "medal")
                        .font(.system(size: 28))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.sets) { set in
                    Text("Set \(set.number): \(set.weight) • \(set.reps) reps")
                        .font(.system(size: 16, weight: set.isHighlighted ? .medium : .light))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}

// MARK: - Models
struct HistoryEntry: Identifiable {
    let id = UUID()
    let date: String
    let sets: [SetData]
    let hasBadge: Bool
}

struct SetData: Identifiable {
    let id = UUID()
    let number: Int
    let weight: String
    let reps: String
    let isHighlighted: Bool
}

// MARK: - Shared Components (reuse from previous views)
struct ExerciseHeader: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Plate-Loaded Chest Press")
                .font(.system(size: 20, weight: .medium))
                .multilineTextAlignment(.center)
            
            Text("Target: X sets • X-X reps")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            
            Text("Plate-Loaded Machine")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 6)
                .background(Color.gray)
                .cornerRadius(20)
        }
    }
}

struct TabSelector: View {
    @Binding var selectedTab: Int
    private let tabs = ["Logger", "Demo", "History"]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "E2E3E4"))
                .frame(height: 40)
            
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: { selectedTab = index }) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                selectedTab == index ?
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.black.opacity(0.47), lineWidth: 1)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                                : nil
                            )
                    }
                }
            }
        }
        .frame(width: 340, height: 40)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    HistoryTabView()
}
```
Key features:

Swift Charts — Native iOS 16+ charting with area fill + line for the progress graph
Stat cards — "Best Set" and "Start Weight" as reusable StatCard components
History entries — Dynamic list with badge indicator (medal icon) for personal records
Set highlighting — First set bold to show best performance per session
Data models — HistoryEntry and SetData ready for Core Data / API integration