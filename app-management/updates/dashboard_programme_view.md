# Dashboard / Programme View  
**(Home Screen – Programme & Split Overview)**

This document describes the **new DashboardView** design, replacing the current static top section with a **dynamic carousel-based header**.

The provided designs show:
- **View 1 (far left)**: Current / legacy dashboard
- **Views 2–4**: New dashboard with a top carousel showing different content states

---

## Core Product Intent

The dashboard should:
- Give users **instant clarity** on their training status
- Surface **one high-value message at a time** (not everything at once)
- Feel dynamic and fresh across sessions
- Keep the primary CTA (“Start Workout”) dominant

The carousel is **informational, not decorative**.

---

## High-Level Layout Structure (SwiftUI)

```swift
NavigationStack {
  ZStack {
    Color(.systemBackground).ignoresSafeArea()

    VStack(spacing: 16) {
      TopHeader
      CarouselSection
      SplitSelector
      StartWorkoutCTA
      WorkoutList
      Spacer(minLength: 16)
    }
    .padding(.horizontal, 16)

    BottomTabBarOverlay
  }
}
```

---

## 1. Top Header

### Elements
- Flame icon + streak count (🔥 32)
- Centered app logo/title (“train”)
- Right-side action icon (scan / settings)

### Implementation Notes
- Fixed height
- Not part of carousel
- Persistent across dashboard states

```swift
HStack {
  HStack(spacing: 4) {
    Text("🔥")
    Text("32").fontWeight(.semibold)
  }

  Spacer()

  Text("train")
    .font(.system(size: 22, weight: .bold))

  Spacer()

  Image(systemName: "qrcode.viewfinder")
}
```

---

## 2. Carousel Section (NEW)

### Purpose
Displays **one contextual card** at a time:
- Training progress
- Learning content
- Engagement prompts

### Behavior
- Horizontal paging
- Auto-height based on content
- Page indicator dots
- 1–3 cards typically

### SwiftUI Structure
```swift
TabView {
  ForEach(carouselItems) { item in
    CarouselCardView(item: item)
  }
}
.tabViewStyle(.page(indexDisplayMode: .automatic))
.frame(height: 140)
```

---

## 3. Carousel Card Types

### A. Weekly Progress Card

**Shown in View 2**

#### Content
- Title: “This Week”
- Subtitle: “0/5 Sessions Complete”
- Weekday indicators (M–S)
- Circular progress markers per day

#### Data Model
```swift
struct WeeklyProgress {
  let completedSessions: Int
  let targetSessions: Int
  let days: [DayProgress]
}
```

#### Notes
- Circles are tappable later (future)
- Visual-only for now

---

### B. Recommended Learning Card

**Shown in View 3**

#### Content
- Title: “Recommended Learning”
- Learning item title (“Barbell Setup”)
- Short description
- Play button icon

#### Product Rules
- Shown when:
  - User is new to a movement
  - User hasn’t watched content recently

#### Data Model
```swift
struct LearningRecommendation {
  let title: String
  let description: String
  let videoID: String
}
```

---

### C. Engagement Prompt Card

**Shown in View 4**

#### Content
- Title: “Leave us a review!”
- Short supporting text
- No CTA button yet (tap whole card)

#### Product Rules
- Low-frequency appearance
- Never blocks core workout flow

---

## 4. Split Selector (Programme Filter)

### Purpose
Allows users to view workouts by split/day type.

Examples:
- P (Push)
- L (Legs)
- Full Body (selected)

### Behavior
- Horizontal list of pills
- One active at a time
- Updates workout list below

```swift
ScrollView(.horizontal, showsIndicators: false) {
  HStack(spacing: 8) {
    ForEach(splits) { split in
      SplitPillView(split: split)
    }
  }
}
```

Claude note:
> Persist last selected split between sessions.

---

## 5. Primary CTA – Start Workout

### Rules
- Always visible
- Always enabled
- Highest visual priority below carousel

```swift
Button("Start Workout") {
  startWorkout()
}
.buttonStyle(.borderedProminent)
```

---

## 6. Workout List

### Content
- Exercise thumbnail (video preview)
- Exercise name
- Sets × reps
- Muscle group illustration

### Behavior
- Scrollable
- Filtered by selected split
- Tappable rows

```swift
ScrollView {
  VStack(spacing: 12) {
    ForEach(workouts) { workout in
      WorkoutRowView(workout: workout)
    }
  }
}
```

---

## 7. Bottom Navigation

### Tabs
- Home (active)
- Milestones
- Library
- Profile (floating button)

### Notes
- Matches existing implementation
- No behavior change

---

## Migration Notes (Old → New)

### Removed
- Static “Hey, [Name]” greeting
- Always-on weekly progress block

### Added
- Dynamic carousel
- Context-aware messaging
- Scalable content injection point

---

## Claude Code Summary

Build a SwiftUI dashboard view with:
- Fixed top header (streak + branding)
- Horizontal carousel with 3 card types:
  - Weekly progress
  - Learning recommendation
  - Engagement prompt
- Split selector pills
- Persistent “Start Workout” CTA
- Scrollable workout list
- Existing bottom navigation

Carousel content is **data-driven and reorderable**.  
Only one card is shown at a time to reduce cognitive load.
