# Exercise Detail View
**(Logger / Demo / History Tabs)**

## Core Product Intent
This screen is the **primary workout interaction point** — where users actually execute their workout:
- **Logger**: Fast set entry with minimal friction
- **Demo**: Learn correct form before lifting
- **History**: See progress trajectory to stay motivated

The three-tab design keeps context while switching between "doing", "learning", and "reviewing".

---

## Screen Structure

### Navigation Header

```swift
struct ExerciseDetailHeader {
  let workoutName: String      // e.g., "Full Body"
  let exerciseIndex: Int       // Current position (1-based)
  let totalExercises: Int      // Total in workout
}
```

### Layout
```swift
HStack {
  Button(action: goBack) {
    Image(systemName: "arrow.left")
  }
  
  Spacer()
  
  Text(workoutName)
    .font(.system(size: 17, weight: .semibold))
  
  Spacer()
  
  Text("\(exerciseIndex)/\(totalExercises)")
    .foregroundColor(.secondary)
}
```

---

## Tab Selector

### Product Rules
- Three equal-width segments
- Selected tab has pill/capsule background
- Unselected tabs are plain text
- Tapping switches content instantly (no animation delay)

### Implementation
```swift
enum ExerciseTab: String, CaseIterable {
  case logger = "Logger"
  case demo = "Demo"
  case history = "History"
}

@State private var selectedTab: ExerciseTab = .logger
```

### UI
```swift
HStack(spacing: 0) {
  ForEach(ExerciseTab.allCases, id: \.self) { tab in
    Button {
      selectedTab = tab
    } label: {
      Text(tab.rawValue)
        .font(.system(size: 15, weight: .medium))
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
          Capsule()
            .fill(selectedTab == tab ? Color(.systemGray5) : Color.clear)
        )
    }
    .foregroundColor(.primary)
  }
}
```

---

## Exercise Info Header (Shared Across All Tabs)

### Product Intent
Persistent context — user always knows what exercise they're on.

### Data Model
```swift
struct ExerciseInfo {
  let name: String              // "Plate-Loaded Chest Press"
  let targetSets: String        // "X sets"
  let targetReps: String        // "X-X reps"
  let equipmentType: String     // "Plate-Loaded Machine"
}
```

### Layout
```swift
VStack(spacing: 8) {
  Text(exercise.name)
    .font(.system(size: 22, weight: .bold))
    .multilineTextAlignment(.center)
  
  Text("Target: \(exercise.targetSets) • \(exercise.targetReps)")
    .font(.system(size: 15))
    .foregroundColor(.secondary)
  
  Text(exercise.equipmentType)
    .font(.system(size: 14, weight: .medium))
    .padding(.horizontal, 16)
    .padding(.vertical, 6)
    .background(Color.primary)
    .foregroundColor(Color(.systemBackground))
    .clipShape(Capsule())
}
```

---

## 1. Logger Tab

### Core Product Intent
**Fastest possible set logging.** Every tap saved = higher workout completion rate.

### 1.1 Warm-Up Suggestion

#### Product Rules
- Shown at top of logging card
- Suggests 50-70% of working weight
- Includes rep count
- Shows weight increase indicator (green "+12" style)

#### Data Model
```swift
struct WarmUpSuggestion {
  let percentageRange: String   // "50-70%"
  let suggestedWeight: Int      // Calculated from last session
  let suggestedReps: Int        // e.g., 10
  let weightIncrease: Int?      // Optional: show if progressing
}
```

#### Layout
```swift
HStack {
  VStack(alignment: .leading, spacing: 4) {
    Text("Suggested warm-up set")
      .font(.system(size: 14))
      .foregroundColor(.secondary)
    Text("\(warmUp.suggestedWeight) kg (\(warmUp.percentageRange)) • \(warmUp.suggestedReps) reps")
      .font(.system(size: 15, weight: .medium))
  }
  
  Spacer()
  
  if let increase = warmUp.weightIncrease {
    Text("+ \(increase)")
      .font(.system(size: 17, weight: .bold))
      .foregroundColor(.green)
  }
}
```

---

### 1.2 Set Entry Rows

#### Product Rules
- Pre-populated with target number of sets
- Each row: Set number + kg input + reps input + completion checkmark
- Inputs are text fields (numeric keyboard)
- Checkmark confirms set completion
- "Add Set" button at bottom for additional sets

#### Data Model
```swift
struct SetEntry: Identifiable {
  let id: UUID
  let setNumber: Int
  var weight: Int?
  var reps: Int?
  var isCompleted: Bool
}
```

#### Layout
```swift
VStack(spacing: 16) {
  ForEach($sets) { $set in
    HStack(spacing: 12) {
      Text("\(set.setNumber)")
        .font(.system(size: 17, weight: .semibold))
        .frame(width: 24)
      
      TextField("kg", value: $set.weight, format: .number)
        .keyboardType(.numberPad)
        .textFieldStyle(.roundedBorder)
        .frame(width: 70)
      
      TextField("reps", value: $set.reps, format: .number)
        .keyboardType(.numberPad)
        .textFieldStyle(.roundedBorder)
        .frame(width: 70)
      
      Button {
        set.isCompleted.toggle()
      } label: {
        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
          .font(.system(size: 24))
          .foregroundColor(set.isCompleted ? .green : .gray)
      }
    }
  }
  
  // Add Set Button
  Button {
    addSet()
  } label: {
    HStack {
      Text("Add Set")
        .font(.system(size: 15))
      Spacer()
    }
    .padding()
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
        .foregroundColor(.gray)
    )
  }
}
.padding(20)
.background(
  RoundedRectangle(cornerRadius: 16)
    .stroke(Color.primary, lineWidth: 1)
)
```

---

### 1.3 Submit Exercise Button

#### Product Rules
- Full-width primary action
- Always visible at bottom
- Advances to next exercise or completes workout

```swift
Button {
  submitExercise()
} label: {
  Text("Submit exercise")
    .font(.system(size: 17, weight: .semibold))
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(Color.primary)
    .cornerRadius(12)
}
```

---

## 2. Demo Tab

### Core Product Intent
**Reduce gym anxiety.** Users can learn form without asking strangers or looking stupid.

### 2.1 Video Player

#### Product Rules
- Prominent video thumbnail with play button
- Loops demonstration video
- Muted by default
- Video sourced per exercise from database

#### Data Model
```swift
struct ExerciseDemo {
  let videoURL: URL
  let thumbnailURL: URL?
}
```

#### Layout
```swift
ZStack {
  // Video player or thumbnail
  RoundedRectangle(cornerRadius: 16)
    .fill(Color(.systemGray6))
    .aspectRatio(16/9, contentMode: .fit)
  
  // Play button overlay
  Image(systemName: "play.fill")
    .font(.system(size: 32))
    .foregroundColor(.gray)
}
.onTapGesture {
  playVideo()
}
```

---

### 2.2 Equipment Section

#### Product Rules
- Horizontal row of equipment images
- Shows all equipment needed for exercise
- Images are data-driven from exercise definition

#### Data Model
```swift
struct Equipment: Identifiable {
  let id: UUID
  let name: String
  let imageURL: URL
}
```

#### Layout
```swift
VStack(alignment: .leading, spacing: 12) {
  Text("Equipment")
    .font(.system(size: 17, weight: .semibold))
  
  HStack(spacing: 16) {
    ForEach(equipment) { item in
      AsyncImage(url: item.imageURL) { image in
        image.resizable().aspectRatio(contentMode: .fit)
      } placeholder: {
        Image(systemName: "photo")
      }
      .frame(width: 60, height: 60)
    }
  }
}
```

---

### 2.3 Active Muscle Groups

#### Product Rules
- Horizontal row of muscle group images
- Visual education on what's being worked
- Encourages mind-muscle connection

#### Data Model
```swift
struct MuscleGroup: Identifiable {
  let id: UUID
  let name: String
  let imageURL: URL
}
```

#### Layout
```swift
VStack(alignment: .leading, spacing: 12) {
  Text("Active Muscle Groups")
    .font(.system(size: 17, weight: .semibold))
  
  HStack(spacing: 16) {
    ForEach(muscleGroups) { group in
      AsyncImage(url: group.imageURL) { image in
        image.resizable().aspectRatio(contentMode: .fit)
      } placeholder: {
        Image(systemName: "photo")
      }
      .frame(width: 60, height: 60)
    }
  }
}
```

---

### 2.4 Instructions

#### Product Rules
- Numbered step-by-step instructions
- Contained in bordered card
- Clear, actionable language

#### Data Model
```swift
struct ExerciseInstructions {
  let steps: [String]
}
```

#### Layout
```swift
VStack(alignment: .leading, spacing: 12) {
  Text("Instructions")
    .font(.system(size: 17, weight: .semibold))
  
  VStack(alignment: .leading, spacing: 8) {
    ForEach(Array(instructions.steps.enumerated()), id: \.offset) { index, step in
      HStack(alignment: .top, spacing: 8) {
        Text("\(index + 1).")
          .font(.system(size: 15))
          .foregroundColor(.secondary)
        Text(step)
          .font(.system(size: 15))
      }
    }
  }
}
.padding(16)
.background(
  RoundedRectangle(cornerRadius: 12)
    .stroke(Color(.systemGray4), lineWidth: 1)
)
```

---

## 3. History Tab

### Core Product Intent
**Visual proof of progress.** Seeing gains keeps users coming back.

### 3.1 Stats Summary Cards

#### Product Rules
- Two side-by-side stat cards at top
- "Best Set" shows personal best weight × reps
- "Start Weight" shows first recorded weight (baseline)
- Provides instant context before diving into history

#### Data Model
```swift
struct ExerciseStats {
  let bestSetWeight: Int
  let bestSetReps: Int
  let startWeight: Int
}
```

#### Layout
```swift
HStack(spacing: 12) {
  StatCard(title: "Best Set", value: "\(stats.bestSetWeight) kg • \(stats.bestSetReps) reps")
  StatCard(title: "Start Weight", value: "\(stats.startWeight) kg")
}

// Reusable StatCard
struct StatCard: View {
  let title: String
  let value: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.system(size: 13))
        .foregroundColor(.secondary)
      Text(value)
        .font(.system(size: 15, weight: .semibold))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 10)
        .stroke(Color(.systemGray4), lineWidth: 1)
    )
  }
}
```

---

### 3.2 Progress Chart

#### Product Rules
- Line chart showing weight progression over time
- Filled area below line for visual impact
- Interactive: draggable dot shows specific session data
- X-axis: time/sessions
- Y-axis: weight (kg)

#### Data Model
```swift
struct ProgressDataPoint: Identifiable {
  let id: UUID
  let date: Date
  let weight: Int
}
```

#### Layout
```swift
Chart(progressData) { point in
  LineMark(
    x: .value("Date", point.date),
    y: .value("Weight", point.weight)
  )
  .interpolationMethod(.catmullRom)
  
  AreaMark(
    x: .value("Date", point.date),
    y: .value("Weight", point.weight)
  )
  .foregroundStyle(
    LinearGradient(
      colors: [Color.gray.opacity(0.3), Color.clear],
      startPoint: .top,
      endPoint: .bottom
    )
  )
}
.frame(height: 160)
.chartXAxis(.hidden)
.chartYAxis(.hidden)
```

---

### 3.3 Session History List

#### Product Rules
- Chronological list of past sessions (newest first)
- Each card shows: date, all sets with weight/reps
- Medal/ribbon icon indicates if session was a PB
- Best set in each session shown in **bold**
- Scrollable list for all history

#### Data Model
```swift
struct SessionRecord: Identifiable {
  let id: UUID
  let date: Date
  let dayName: String           // e.g., "Monday"
  let sets: [SetRecord]
  let isPB: Bool                // Personal best achieved
}

struct SetRecord: Identifiable {
  let id: UUID
  let setNumber: Int
  let weight: Int
  let reps: Int
  let isBestSet: Bool           // Best set of this session
}
```

#### Layout
```swift
ScrollView {
  LazyVStack(spacing: 12) {
    ForEach(sessionHistory) { session in
      SessionHistoryCard(session: session)
    }
  }
}

struct SessionHistoryCard: View {
  let session: SessionRecord
  
  var body: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 6) {
        // Date header
        Text("\(session.date.formatted(.dateTime.day().month().year())) - \(session.dayName)")
          .font(.system(size: 15, weight: .semibold))
        
        // Sets
        ForEach(session.sets) { set in
          Text("Set \(set.setNumber): \(set.weight)kg • \(set.reps) reps")
            .font(.system(size: 14, weight: set.isBestSet ? .semibold : .regular))
            .foregroundColor(set.isBestSet ? .primary : .secondary)
        }
      }
      
      Spacer()
      
      // PB indicator
      if session.isPB {
        Image(systemName: "medal")
          .font(.system(size: 24))
          .foregroundColor(.orange)
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(.systemGray4), lineWidth: 1)
    )
  }
}
```

---

## Bottom Tab Bar (Global)

### Product Rules
- Persistent across all screens
- Four tabs: Workouts, Awards, Play, Profile
- Current tab highlighted

```swift
struct MainTabBar: View {
  @Binding var selectedTab: MainTab
  
  var body: some View {
    HStack {
      TabBarItem(tab: .workouts, icon: "dumbbell", label: "Workouts", selectedTab: $selectedTab)
      TabBarItem(tab: .awards, icon: "medal", label: nil, selectedTab: $selectedTab)
      TabBarItem(tab: .play, icon: "play.fill", label: nil, selectedTab: $selectedTab)
      TabBarItem(tab: .profile, icon: "person.circle", label: nil, selectedTab: $selectedTab)
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 12)
  }
}
```

---

## Data Flow Summary

```swift
struct ExerciseDetailViewModel: ObservableObject {
  // Exercise context
  let exercise: ExerciseInfo
  let workoutContext: ExerciseDetailHeader
  
  // Logger tab
  @Published var sets: [SetEntry]
  let warmUpSuggestion: WarmUpSuggestion?
  
  // Demo tab
  let demo: ExerciseDemo
  let equipment: [Equipment]
  let muscleGroups: [MuscleGroup]
  let instructions: ExerciseInstructions
  
  // History tab
  let stats: ExerciseStats
  let progressData: [ProgressDataPoint]
  let sessionHistory: [SessionRecord]
  
  // Actions
  func submitExercise() { }
  func addSet() { }
}
```

---

## Claude Code Summary

Build a SwiftUI exercise detail screen with three tabs:

**Logger Tab:**
- Warm-up suggestion with weight increase indicator
- Dynamic set entry rows (kg + reps + completion toggle)
- Add Set functionality
- Submit Exercise button

**Demo Tab:**
- Video player with thumbnail
- Equipment images (horizontal row)
- Active muscle group images (horizontal row)
- Numbered instructions in bordered card

**History Tab:**
- Best Set + Start Weight stat cards
- Interactive line/area chart showing progression
- Scrollable session history with PB indicators

**Shared:**
- Tab selector (Logger/Demo/History)
- Exercise info header (name, targets, equipment type)
- Bottom tab bar

All content must be **data-driven** and passed into views via view models.
