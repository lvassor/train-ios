Ok we need to make some design changes. These changes relate directly to the what the user experiences when they click on an exercise inside of their workout. This opens the exercise logger, with the choice of navigating to the demo tab, and history tab. the changes in this document relate explicitly to these 3 sections. In order to detail the changes I desire, I will go through each section, describe the current design and then provde code for the target design that claude has derived from figma. however, note that code has directly converted from designs that contain variable strings for example. so i have left comments in the code to signify where hard coded strings are in fact variable. I walk through the state from the top of the screen to the bottom of the screen. In this section I address the demo page.

# 1. Logger Page
## Current State
1. Rounded corner container containing Back button and left chevrow on the left hand side. On the the right hand side, "Exercise X/5" where X is the number of exercises within the current active workout that have been submitted. This corresponds to the progress of the progress bar.
2. Orange progress bar which sits flush with the bottom border of the container above (point 1.). Progress bar progresses in line with the number of exercises submitted in the active workout thus far.
3. Pill toolbar allowing quick navigation between Logger, Demo and History pages using native glass slider design.
4. Below the toolbar is a left-aligned string (not in a container) displaying the exercise title for the exercise being viewed, e.g. Barbell Bench Press.
5. Below this is a rounded corner video display which renders the video of the exercise being viewed from the Bunnt streaming service via the exercise to bunny mapping table. this view can be expanded to full screen using overlayed expand arrows.
6. Beneath the video view we have two cards side by side. The left card has child elements: title "Muscles" and pill shaped tags for the primary and secondary muscle groups associated with the exercise. The right card has child elements: title "Equipment" and an equipment tag containing a symbol e.g. "Barbells".
7. Beneath this we have yet another card, whose child elements are the exercise instructions. "How to Perform" title followed by enumerated list of actions.
8. Below this we have the Submit Exercise button in grey, this becomes illuminated in accent colour only when all sets have been marked as complete.
9. Beneath this is the main toolbar allow the user to navigate to home, milestones, library of their account settings.

## Target State
This code has the correct text colours for the app's light mode. However, in dark mode you need to interpret these intelligently where black colours become white.
```swift
import SwiftUI

struct DemoTabView: View {
    @State private var selectedTab = 1 // Demo selected
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { }) { // Back button
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight: .medium))
                    }
                    Spacer()
                    Text("Full Body") // VARIABLE: name of the current session within the user's progarmme, e.g. Full Body, Or Push or Pull or Legs or Upper - these are stored against the programme.
                        .font(.system(size: 18, weight: .medium))
                    Spacer()
                    Text("1/5")// VARIABLE: represents the number of exercises completed within the session out of the total number.
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                
                // Tab Selector // Pill toolbar that we have currenctly implemented (apple native component) but the width now spans the view port
                TabSelector(selectedTab: $selectedTab)
                    .padding(.top, 16)
                
                // Exercise Info
                ExerciseHeader()
                    .padding(.top, 20)
                
                // Video Player Card - same as what we currently have from bunny.net streaaming
                VideoPlayerCard()
                    .padding(.horizontal, 18)
                    .padding(.top, 24)
                
                // Equipment Section - displays row of equipment images. use placeholder image symbol for now, horizontally stacked in a row
                InfoSection(title: "Equipment", items: ["Bench", "Barbell", "Plates"])
                    .padding(.top, 24)
                
                // Muscle Groups Section - displays row of muscle groups. these use thhe same muscle groups images and highlights as in the current account settings - see separate code section below
                InfoSection(title: "Active Muscle Groups", items: ["Chest", "Triceps", "Shoulders"])
                    .padding(.top, 16)
                
                // Instructions Card
                InstructionsCard()
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom: 100)
            }
        }
        .background(Color.white)
    }
}

// MARK: - Exercise Header
struct ExerciseHeader: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Plate-Loaded Chest Press") // VARIABLE: current exercise name
                .font(.system(size: 20, weight: .medium))
                .multilineTextAlignment(.center)
            
            Text("Target: X sets • X-X reps")// VARIABLE X represents number of sets and rep range assigned in user's programme.
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            
            Text("Plate-Loaded Machine")// VARIABLE: this is a tag style with the stying described below. multiple tags may be present if there are multiple pieces of equipment against the exercise
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 6)
                .background(Color.gray)
                .cornerRadius(20)
        }
    }
}

// MARK: - Video Player Card
struct VideoPlayerCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1)
                .frame(height: 192)
            
            // Play button
            Button(action: { }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
    }
}

// MARK: - Info Section (Equipment / Muscle Groups)
struct InfoSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 50)
            
            HStack(spacing: 35) {
                ForEach(items, id: \.self) { item in
                    PlaceholderTile(label: item)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Placeholder Tile
struct PlaceholderTile: View {
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                
                // Mountain placeholder icon
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
        }
    }
}

// MARK: - Instructions Card
struct InstructionsCard: View { // Same as current instruction steps
    let instructions = [
        "Instructions in here",
        "More instructions",
        "Even more"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.system(size: 16, weight: .medium))
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.system(size: 14, weight: .light))
                            .opacity(0.8)
                        Text(instruction)
                            .font(.system(size: 14, weight: .light))
                            .opacity(0.8)
                    }
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}

// MARK: - Shared Tab Selector (reuse from previous view)
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

// MARK: - Color Extension
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
    DemoTabView()
}
```

Located at: Views/ProfileView.swift (around lines with StaticMuscleView)
```swift
// Priority Muscle Groups with mini body diagrams
VStack(spacing: Spacing.md) {
    Text("Priority Muscles")
        .font(.trainCaption)
        .foregroundColor(.trainTextSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    HStack(spacing: Spacing.lg) {
        // Get muscle groups from questionnaire data
        ForEach(getPriorityMuscleGroups(), id: \.self) { muscleGroup in
            VStack(spacing: Spacing.sm) {
                StaticMuscleView(
                    muscleGroup: muscleGroup,
                    gender: getUserGender(),
                    size: 90,
                    useUniformBaseColor: true
                )
                .frame(width: 90, height: 90)
                Text(muscleGroup)
                    .font(.trainCaption)
                    .foregroundColor(.trainTextSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}
```