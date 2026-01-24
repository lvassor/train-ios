Ok we need to make some design changes. These changes relate directly to the what the user experiences when they click on an exercise inside of their workout. This opens the exercise logger, with the choice of navigating to the demo tab, and history tab. the changes in this document relate explicitly to these 3 sections. In order to detail the changes I desire, I will go through each section, describe the current design and then provde code for the target design that claude has derived from figma. however, note that code has directly converted from designs that contain variable strings for example. so i have left comments in the code to signify where hard coded strings are in fact variable. I walk through the state from the top of the screen to the bottom of the screen. In this section I address the logger page.

# 1. Logger Page
## Current State
1. Rounded corner container containing Back button and left chevrow on the left hand side. On the the right hand side, "Exercise X/5" where X is the number of exercises within the current active workout that have been submitted. This corresponds to the progress of the progress bar.
2. Orange progress bar which sits flush with the bottom border of the container above (point 1.). Progress bar progresses in line with the number of exercises submitted in the active workout thus far.
3. Pill toolbar allowing quick navigation between Logger, Demo and History pages using native glass slider design.
4. Below the toolbar is another container with rounded corners. The child elements of this container include the exercise title e.g. Barbell Bench Press in white font. Below the title string is a pill shaped tag with a slight tint that contains the equipment associated with the exercise and corresponding symbol, e.g. "Barbells" with a weight symbol to the left. There is then a faint line divider. Below this line is the target sets and rep range for the exercise, with "Target" in one colour and the sets and reps in orange colour.
5. Below this is a new container. The child elements of this container include the title "Log Sets" (top left) which remains constant across all exercises. In the top-right, a tool bar allows the user to switch units between metric and imperial. Below this are the rows and columns that allow the user to record the reps and weight of the different sets they are performing for the exercise. each row contains the set number, integer input for the reps and likewise for the weight, as well as the ability to tick the set as complete. 
6. Beneath this container is the "Submit Exercise" CTA button, allowing the user to mark the exercise as complete and log the data.this button is in grey, this becomes illuminated in accent colour only when all sets have been marked as complete.
7. Beneath this is the main toolbar allow the user to navigate to home, milestones, library of their account settings.

## Target State
This code has the correct text colours for the app's light mode. However, in dark mode you need to interpret these intelligently where black colours become white. You should also retain the nice apple style gradient we have behind the Submit Exercise button (which becomes "Complete Exercise") for any scrollable content that goes behind this CTA button.
```swift
import SwiftUI

struct WorkoutLoggerView: View {
    @State private var selectedTab = 0
    @State private var sets: [WorkoutSet] = [
        WorkoutSet(kg: "", reps: ""),
        WorkoutSet(kg: "", reps: ""),
        WorkoutSet(kg: "", reps: "")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { }) {
                    Image(systemName: "chevron.left") // back button
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .medium))
                }
                Spacer()
                Text("Full Body") // VARIABLE: name of the current session within the user's progarmme, e.g. Full Body, Or Push or Pull or Legs or Upper - these are stored against the programme.
                    .font(.system(size: 18, weight: .medium))
                Spacer()
                Text("1/5") // VARIABLE: represents the number of exercises completed within the session out of the total number.
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            
            // Tab Selector
            TabSelector(selectedTab: $selectedTab) // Pill toolbar that we have currenctly implemented (apple native component) but the width now spans the view port
                .padding(.top, 16)
            
            // Exercise Info
            VStack(spacing: 4) {
                Text("Plate-Loaded Chest Press") // VARIABLE: current exercise name
                    .font(.system(size: 20, weight: .medium))
                    .multilineTextAlignment(.center)
                
                Text("Target: X sets • X-X reps") // VARIABLE X represents number of sets and rep range assigned in user's programme.
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text("Plate-Loaded Machine") // VARIABLE: this is a tag style with the stying described below. multiple tags may be present if there are multiple pieces of equipment against the exercise
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                    .background(Color.gray)
                    .cornerRadius(20)
            }
            .padding(.top, 20)
            
            // Sets Card
            SetsCard(sets: $sets)
                .padding(.horizontal, 18)
                .padding(.top, 24)
            
            Spacer()
            
            // Complete Button // should actually retain primary accent colour
            Button(action: { }) {
                Text("Complete Exercise")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.black) 
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
        }
        .background(Color.white)
    }
}

// MARK: - Tab Selector // Pill toolbar that we have currenctly implemented (apple native component) . keep the glass apple styling, just amend the sizing to the code below.
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

// MARK: - Sets Card
struct SetsCard: View {
    @Binding var sets: [WorkoutSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Warm-up suggestion header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested warm-up set")
                        .font(.system(size: 14, weight: .light))
                        .opacity(0.8)
                    Text("X kg (50-70%) • 10 reps")
                        .font(.system(size: 14, weight: .medium))
                        .opacity(0.8)
                }
                Spacer()
                Text("+ 12") // VARIABLE: rep counter, see app_rules.md for rules. appears when first set exceeds previous week's reps. but requires slight delay on user input so that double digits don't change the rep count to quickly - poor UX.
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "4DCA73"))
            }
            .padding(.bottom, 8)
            
            // Set rows 
            ForEach(sets.indices, id: \.self) { index in
                SetRow(setNumber: index + 1, set: $sets[index])
            }
            
            // Add Set button
            Button(action: { sets.append(WorkoutSet(kg: "", reps: "")) }) {
                Text("Add Set")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(.black)
                    )
            }
        }
        .padding(24)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}

// MARK: - Set Row - similar to current set up but lacking headers
struct SetRow: View {
    let setNumber: Int
    @Binding var set: WorkoutSet
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(setNumber)")
                .font(.system(size: 20, weight: .light))
                .frame(width: 20)
            
            // Weight input
            TextField("kg", text: $set.kg)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black.opacity(0.4))
                .multilineTextAlignment(.center)
                .frame(width: 98, height: 35)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 1)
                )
            
            // Reps input
            TextField("reps", text: $set.reps)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black.opacity(0.4))
                .multilineTextAlignment(.center)
                .frame(width: 98, height: 35)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 1)
                )
            
            // Checkmark
            Circle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                )
        }
    }
}

// MARK: - Model
struct WorkoutSet: Identifiable {
    let id = UUID()
    var kg: String
    var reps: String
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
    WorkoutLoggerView()
}

// Below Compleete Button we have the exact same tool bar as current for navigating home, to milestones, or libary or account settings
```