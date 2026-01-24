We're going to redesign our DashboardView, Exercise overview and the user's ability to edit/update their workout. We also now incorporate video thumbails and muscle selectros.

The below contains the figma-derived code for the dashboard view of the app.
What's important to note is that Claude has produced this code directly from the designs in Figma which may appear as raw strings when elements are in fact variable, these are noted in the code comments.

Where we already have dynamic behaviour or content in the current code, you should use the figma derived code below to fetch stylistic information like sizes, colours, spacing, but not replace function.

This code has the correct text colours for the app's light mode. However, in dark mode you need to interpret these intelligently where black colours become white. e.g. retaining the app's black and white gradient background already in place.

```swift
import SwiftUI

struct DashboardView: View {
    @State private var selectedWorkoutType = "Full Body"
    @State private var completedDays: Set<String> = []
    
    private let workoutTypes = ["P", "P", "Full Body", "L", "L"] // VARIABLE: Represent the different sessions in the programme, acronymised e.g. a Push Pull Legs program would show "P", "Pu", "L" (Pu = Pull) - we already have this system in place. "Full Body" in this instance reads as the full name (expands on click). Keep the current function.
    private let weekDays = ["M", "T", "W", "T", "F", "S", "S"] // Order of week days in the calendar, currently in place.
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(streakCount: 32)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Weekly Progress Card
                    WeeklyProgressCard(
                        completedSessions: 0, // VARIABLE: depends how many sessions have been recorded.
                        totalSessions: 5, // VARIABLE: depends on how many sessions are in the user's program
                        weekDays: weekDays,
                        completedDays: completedDays
                    )
                    
                    // Page Indicator - note that this sits outside the border of the weekly progress card.
                    HStack(spacing: 8) {
                        Circle().fill(Color.gray).frame(width: 10, height: 10)
                        Circle().stroke(Color.black, lineWidth: 1).frame(width: 10, height: 10)
                        Circle().stroke(Color.black, lineWidth: 1).frame(width: 10, height: 10)
                    }
                    
                    // Workout Type Filter
                    WorkoutTypeFilter(
                        types: workoutTypes,
                        selected: $selectedWorkoutType
                    )
                    
                    // Start Workout Button
                    Button(action: { /* Start workout */ }) {
                        Text("Start Workout") // should match current orange accent colour.
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(16)
                    }
                    
                    // Exercise List // VARIABLE: depends on exercises produced by the generator, whichever are exercises belong to day X of the program. These are listed because they are on the "Full Body" day which, in the figma design, has been selected. this exercise list is scrollable. gradient mask behind the master home/milestones/library toolbar should be retained.
                    VStack(spacing: 12) {
                        ExerciseCard(
                            name: "Plate-Loaded Chest Press", 
                            sets: "X sets • X-X reps", // VARIABLE: whatever sets and reps were assigned to exercise
                            thumbnail: "exercise_chest", // VARIABLE" video thumbnail of the bunny video (see video mapping to exercise name), user can click this thumbnail to view the video
                            muscleImage: "muscle_chest" // This is a view of the target muscles of the exercise. We use SVG highlight files - look at the muscle selector that we use in the demo page for doing this. whatever the primary and secondary muscle group is of the corresponding exercise, these should be visualised in the image.
                        )
                        ExerciseCard(
                            name: "Leg Extension",
                            sets: "X sets • X-X reps",
                            thumbnail: "exercise_legs",
                            muscleImage: "muscle_legs"
                        )
                        ExerciseCard(
                            name: "Incline Dumbbell Curl",
                            sets: "X sets • X-X reps",
                            thumbnail: "exercise_biceps",
                            muscleImage: "muscle_arms"
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 100)
            }
            
            Spacer()
        }
        .background(Color.white)
        .overlay(alignment: .bottom) {
            TabBarView()
        }
    }
}

// MARK: - Header
struct HeaderView: View {
    let streakCount: Int
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text("🔥")
                Text("\(streakCount)")
                    .font(.system(size: 16, weight: .medium))
            }
            
            Spacer()
            
            Text("train") // CHANGE: This is, in fact, the train with text svg logo.
                .font(.custom("MuseoModerno-Bold", size: 30))
                .tracking(-0.9)
            
            Spacer()
            
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 24))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Weekly Progress Card
struct WeeklyProgressCard: View {
    let completedSessions: Int
    let totalSessions: Int
    let weekDays: [String]
    let completedDays: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("This Week")
                    .font(.system(size: 14, weight: .medium))
                Text("\(completedSessions)/\(totalSessions) Sessions Complete")
                    .font(.system(size: 12, weight: .light))
            }
            
            HStack(spacing: 12) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: 6) {
                        Text(day)
                            .font(.system(size: 12, weight: .light))
                        Circle()
                            .stroke(Color.black, lineWidth: 1)
                            .frame(width: 32, height: 32)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}

// MARK: - Workout Type Filter
struct WorkoutTypeFilter: View {
    let types: [String]
    @Binding var selected: String
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(types, id: \.self) { type in
                Button(action: { selected = type }) {
                    Text(type)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selected == type ? .white : .black)
                        .padding(.horizontal, type == "Full Body" ? 20 : 16)
                        .padding(.vertical, 10)
                        .background(selected == type ? Color.gray : Color.white)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selected == type ? Color.white : Color.black, lineWidth: 0.5)
                        )
                }
            }
        }
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    let name: String
    let sets: String
    let thumbnail: String
    let muscleImage: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail with play button - bunny video thumbnail
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 64)
                // Replace with actual image: Image(thumbnail) - SVG muscle highlighter
                
                Image(systemName: "play.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .offset(x: 4, y: -4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(2)
                Text(sets)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            // Muscle illustration placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 48, height: 50)
            // Replace with actual image: Image(muscleImage)
        }
        .padding(16)
        .background(Color(hex: "F2EFEF"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 1)
    }
}

// MARK: - Tab Bar
struct TabBarView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        HStack {
            TabBarItem(icon: "house.fill", title: "Home", isSelected: selectedTab == 0)
                .onTapGesture { selectedTab = 0 }
            TabBarItem(icon: "flag", title: "Milestones", isSelected: selectedTab == 1)
                .onTapGesture { selectedTab = 1 }
            TabBarItem(icon: "chart.bar", title: "Library", isSelected: selectedTab == 2)
                .onTapGesture { selectedTab = 2 }
            TabBarItem(icon: "person", title: "", isSelected: selectedTab == 3)
                .onTapGesture { selectedTab = 3 }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 40)
                .fill(Color(hex: "1C1C1E"))
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 10))
            }
        }
        .foregroundColor(isSelected ? .orange : .white)
        .frame(maxWidth: .infinity)
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
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#Preview {
    DashboardView()
}
```

The dashboard view then links through to the workout view via the "Start Workout" button, which uses a lot of similar elements. Code below:

```swift
import SwiftUI

struct SessionOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    let workoutTitle: String
    let exercises: [Exercise]
    var onComplete: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            SessionHeader(
                title: workoutTitle,
                onBack: { dismiss() },
                onEdit: { /* Edit action */ }
            )
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Suggested Warm-Up Section
                    SectionHeader(title: "Suggested Warm-Up")
                    
                    WarmUpCard(
                        name: "Upper Body Mobility",
                        detail: "X exercises • X minutes",
                        // Same thumbnail as DashboardView exercises
                        thumbnail: "exercise_chest"
                    )
                    
                    // Workout Section
                    SectionHeader(title: "Workout")
                    
                    // Exercise List with connectors
                    VStack(spacing: 0) {
                        ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                            VStack(spacing: 0) {
                                SessionExerciseCard(
                                    name: exercise.name,
                                    sets: exercise.setsDescription,
                                    // Same images as DashboardView - reuse from shared assets
                                    thumbnail: exercise.thumbnailImage,
                                    muscleImage: exercise.muscleImage
                                )
                                
                                // Connector line (not on last item)
                                if index < exercises.count - 1 {
                                    ExerciseConnector()
                                }
                            }
                        }
                    }
                    
                    // Complete Workout Button
                    Button(action: onComplete) {
                        Text("Complete Workout")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.white)
                            .cornerRadius(16)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 100)
            }
            
            Spacer()
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .overlay(alignment: .bottom) {
            TabBarView()
        }
    }
}

// MARK: - Session Header
struct SessionHeader: View {
    let title: String
    var onBack: () -> Void
    var onEdit: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
            .frame(width: 24, height: 24)
            
            Spacer()
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: onEdit) {
                Text("Edit")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .light))
            .foregroundColor(.black)
            .padding(.top, 8)
    }
}

// MARK: - Warm-Up Card
struct WarmUpCard: View {
    let name: String
    let detail: String
    let thumbnail: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail with play button
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 64)
                // Same thumbnail images as DashboardView
                // Image(thumbnail).resizable().scaledToFill()
                
                PlayButton()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                Text(detail)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "F2EFEF"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 1)
    }
}

// MARK: - Session Exercise Card
struct SessionExerciseCard: View {
    let name: String
    let sets: String
    let thumbnail: String
    let muscleImage: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail with play button
            // Same thumbnail images as DashboardView - reuse ExerciseCard assets
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 64)
                // Image(thumbnail).resizable().scaledToFill().cornerRadius(8)
                
                PlayButton()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(2)
                Text(sets)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            // Same muscle images as DashboardView - reuse ExerciseCard assets
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 48, height: 50)
            // Image(muscleImage).resizable().scaledToFit()
        }
        .padding(16)
        .background(Color(hex: "F2EFEF"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 1)
    }
}

// MARK: - Play Button
struct PlayButton: View {
    var body: some View {
        Image(systemName: "play.fill")
            .font(.system(size: 10))
            .foregroundColor(.white)
            .padding(6)
            .background(Color.black.opacity(0.6))
            .clipShape(Circle())
            .offset(x: 4, y: -4)
    }
}

// MARK: - Exercise Connector
struct ExerciseConnector: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.black)
                .frame(width: 1, height: 20)
                .padding(.leading, 58) // Align with card center
            Spacer()
        }
    }
}

// MARK: - Exercise Model
struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let setsDescription: String
    let thumbnailImage: String
    let muscleImage: String
}

// MARK: - Preview
#Preview {
    SessionOverviewView(
        workoutTitle: "Full Body Workout",
        exercises: [
            Exercise(
                name: "Plate-Loaded Chest Press",
                setsDescription: "X sets • X-X reps",
                thumbnailImage: "exercise_chest",
                muscleImage: "muscle_chest"
            ),
            Exercise(
                name: "Leg Extension",
                setsDescription: "X sets • X-X reps",
                thumbnailImage: "exercise_legs",
                muscleImage: "muscle_legs"
            ),
            Exercise(
                name: "Incline Dumbbell Curl",
                setsDescription: "X sets • X-X reps",
                thumbnailImage: "exercise_biceps",
                muscleImage: "muscle_arms"
            )
        ]
    )
}
```
Usage from DashboardView:
```swift
// In DashboardView, update the Start Workout button:
@State private var showSessionOverview = false

Button(action: { showSessionOverview = true }) {
    Text("Start Workout")
    // ... existing styling
}
.fullScreenCover(isPresented: $showSessionOverview) {
    SessionOverviewView(
        workoutTitle: "Full Body Workout",
        exercises: exercises, // Pass your exercise data
        onComplete: {
            // Handle workout completion
            showSessionOverview = false
        }
    )
}
```
Video thumbnails and muscle images are the same assets as DashboardView — use a shared asset manager or pass them via the Exercise model
Connector lines between exercises show progression flow
"Complete Workout" CTA is prominent white button for clear action
Swipe-to-dismiss via @Environment(\.dismiss) for smooth UX

clicking the Edit button on the previous button produces this, which allows the user amend their programme (function:swap exercises, delete exercises, or re-order the exercises).
```swift
import SwiftUI

struct SessionEditView: View {
    @Environment(\.dismiss) private var dismiss
    let workoutTitle: String
    @Binding var exercises: [Exercise]
    @State private var isReordering = false
    
    var onAddExercise: () -> Void = {}
    var onSwapExercise: (Exercise) -> Void = { _ in }
    var onRemoveExercise: (Exercise) -> Void = { _ in }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            EditHeader(
                title: workoutTitle,
                onBack: { dismiss() },
                onDone: { dismiss() }
            )
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Top Action Buttons
                    HStack(spacing: 12) {
                        ActionPillButton(title: "Add Exercise", action: onAddExercise)
                        ActionPillButton(title: "Re-order", action: { isReordering.toggle() })
                    }
                    
                    // Suggested Warm-Up Section
                    SectionHeader(title: "Suggested Warm-Up")
                    
                    EditableWarmUpCard(
                        name: "Upper Body Mobility",
                        detail: "X exercises • X minutes",
                        // Same thumbnail as DashboardView
                        thumbnail: "exercise_chest"
                    )
                    
                    // Workout Section
                    SectionHeader(title: "Workout")
                    
                    // Editable Exercise List
                    VStack(spacing: 0) {
                        ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                            VStack(spacing: 0) {
                                EditableExerciseCard(
                                    exercise: exercise,
                                    // Same images as DashboardView - reuse shared assets
                                    onSwap: { onSwapExercise(exercise) },
                                    onRemove: { onRemoveExercise(exercise) }
                                )
                                
                                // Connector line (not on last item)
                                if index < exercises.count - 1 {
                                    ExerciseConnector()
                                }
                            }
                        }
                        .onMove(perform: isReordering ? moveExercise : nil)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 100)
            }
            
            Spacer()
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .overlay(alignment: .bottom) {
            TabBarView()
        }
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Edit Header
struct EditHeader: View {
    let title: String
    var onBack: () -> Void
    var onDone: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
            .frame(width: 24, height: 24)
            
            Spacer()
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

// MARK: - Action Pill Button
struct ActionPillButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "0093ED").opacity(0.15))
                .cornerRadius(16)
        }
    }
}

// MARK: - Editable Warm-Up Card
struct EditableWarmUpCard: View {
    let name: String
    let detail: String
    let thumbnail: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Same thumbnail images as DashboardView
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 64)
                // Image(thumbnail).resizable().scaledToFill().cornerRadius(8)
                
                PlayButton()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                Text(detail)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "0093ED").opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Editable Exercise Card
struct EditableExerciseCard: View {
    let exercise: Exercise
    var onSwap: () -> Void
    var onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise Info Row
            HStack(spacing: 16) {
                // Same thumbnail images as DashboardView - reuse from shared assets
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 64)
                    // Image(exercise.thumbnailImage).resizable().scaledToFill().cornerRadius(8)
                    
                    PlayButton()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(2)
                    Text(exercise.setsDescription)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                // Same muscle images as DashboardView - reuse from shared assets
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 48, height: 50)
                // Image(exercise.muscleImage).resizable().scaledToFit()
            }
            .padding(16)
            
            // Action Buttons Row
            HStack(spacing: 12) {
                ExerciseActionButton(title: "Swap", action: onSwap)
                ExerciseActionButton(title: "Remove", action: onRemove)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(hex: "0093ED").opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Exercise Action Button
struct ExerciseActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "0093ED").opacity(0.2))
                .cornerRadius(16)
        }
    }
}

// MARK: - Preview
#Preview {
    SessionEditView(
        workoutTitle: "Full Body Workout",
        exercises: .constant([
            Exercise(
                name: "Plate-Loaded Chest Press",
                setsDescription: "X sets • X-X reps",
                thumbnailImage: "exercise_chest",
                muscleImage: "muscle_chest"
            ),
            Exercise(
                name: "Leg Extension",
                setsDescription: "X sets • X-X reps",
                thumbnailImage: "exercise_legs",
                muscleImage: "muscle_legs"
            ),
            Exercise(
                name: "Incline Dumbbell Curl",
                setsDescription: "X sets • X-X reps",
                thumbnailImage: "exercise_biceps",
                muscleImage: "muscle_arms"
            )
        ])
    )
}
```
Update SessionOverviewView to navigate to edit mode:
```// In SessionOverviewView, update the header:
@State private var isEditing = false
@State private var editableExercises: [Exercise]

// Initialize editableExercises from exercises in init or onAppear

var body: some View {
    VStack(spacing: 0) {
        SessionHeader(
            title: workoutTitle,
            onBack: { dismiss() },
            onEdit: { isEditing = true }
        )
        // ... rest of view
    }
    .fullScreenCover(isPresented: $isEditing) {
        SessionEditView(
            workoutTitle: workoutTitle,
            exercises: $editableExercises,
            onAddExercise: {
                // Present exercise picker
            },
            onSwapExercise: { exercise in
                // Present swap sheet for this exercise
            },
            onRemoveExercise: { exercise in
                editableExercises.removeAll { $0.id == exercise.id }
            }
        )
    }
}
```