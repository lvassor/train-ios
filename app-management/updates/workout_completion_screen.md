# Workout Completion / Celebration Screen  
**(Post-Workout Submit Experience)**

## Core Product Intent
This screen is not just confirmation — it’s a **motivational feedback loop**:
- Emotional reward (emoji + headline)
- Immediate validation (support message)
- Concrete progress proof (stats + PBs)
- Habit reinforcement (streak)

Everything here should feel **lightweight, positive, and variable** so it doesn’t become stale.

---

## 1. Emoji / Visual Reward (Variable Per Workout)

### Product Rules
- Emoji **varies per workout**
- Selected based on:
  - Workout intensity
  - PB achieved
  - Streak length
  - Or randomized from a “success set”

Examples: ⭐ 🎉 💪 🏆 🏋️ 💯

### Implementation Guidance
- Emoji is **data-driven**, not hardcoded
- Passed into view as a single `String`

```swift
let celebrationEmoji: String
```

### UI
- Large emoji
- Centered
- First thing user sees

```swift
Text(celebrationEmoji)
  .font(.system(size: 48))
  .padding(.top, 8)
```

---

## 2. Strong Completion Message (Primary Headline)

### Product Rules
- **Rotates each workout**
- Short, confident, celebratory

Examples:
- “You smashed this workout!”
- “Another one for the books”
- “Great progress today!”
- “You’re getting stronger!”

### Implementation
```swift
let completionHeadline: String
```

```swift
Text(completionHeadline)
  .font(.system(size: 28, weight: .bold))
  .multilineTextAlignment(.center)
```

---

## 3. Quick Support Message (Secondary Line)

### Product Rules
- Contextual encouragement
- Highlights *why* this workout matters

Examples:
- “That’s your 100th workout!”
- “3rd session this week”
- “First workout of the week”

### Implementation
```swift
let supportMessage: String
```

```swift
Text(supportMessage)
  .font(.system(size: 17))
  .foregroundColor(.secondary)
```

---

## 4. Workout Summary Card (Progress at a Glance)

### Product Intent
Quick, scannable **proof of effort**.

### Metrics
- Total Duration
- Increased Reps
- Overall Weight Lifted

### Data Model
```swift
struct WorkoutSummaryStat {
  let label: String
  let value: String
}
```

### Layout
```swift
VStack(spacing: 16) {
  ForEach(stats) { stat in
    HStack {
      Text(stat.label)
      Spacer()
      Text(stat.value).fontWeight(.semibold)
    }
  }
}
.padding(20)
.background(
  RoundedRectangle(cornerRadius: 16)
    .stroke(Color.primary, lineWidth: 1)
)
```

---

## 5. Today’s PBs (Weight Increases ONLY)

⚠️ **PBs refer ONLY to weight increases**

---

## 6. PB Carousel (Horizontal, Paged)

### Behavior
- Horizontal paging
- One PB per page
- Page indicator dots
- Supports 1 → N PBs

```swift
TabView {
  ForEach(pbs) { pb in
    PBCardView(pb: pb)
  }
}
.tabViewStyle(.page(indexDisplayMode: .always))
.frame(height: 140)
```

---

## 7. PB Card Content

### Data Model
```swift
struct PersonalBest {
  let exerciseName: String
  let previousWeight: Int
  let newWeight: Int
  let bestSetSummary: String
}
```

### Layout
```swift
VStack(alignment: .leading, spacing: 12) {
  Text(pb.exerciseName)
    .font(.system(size: 18, weight: .semibold))

  HStack(spacing: 8) {
    Text("\(pb.previousWeight)kg → \(pb.newWeight)kg")
      .font(.system(size: 22, weight: .bold))
    Image(systemName: "arrow.up")
  }

  Text("Best Set \(pb.bestSetSummary)")
    .font(.system(size: 15))
    .foregroundColor(.secondary)
}
.padding(20)
.background(
  RoundedRectangle(cornerRadius: 16)
    .stroke(Color.primary, lineWidth: 1)
)
```

---

## 8. Streak Increase Section

```swift
HStack {
  VStack(alignment: .leading, spacing: 8) {
    Text("Streak Increase")
      .font(.system(size: 20, weight: .semibold))
    Text(streakMessage)
      .font(.system(size: 16))
      .foregroundColor(.secondary)
  }
  Spacer()
  Text("🔥").font(.system(size: 40))
}
```

---

## 9. Navigation & Dismissal

- **Done** → dismiss screen  
- **Share** → trigger share sheet

---

## Claude Code Summary

Build a SwiftUI modal celebration screen shown after workout submission with:
- Variable emoji reward
- Rotating completion headline
- Contextual support message
- Summary stats card
- Horizontal carousel of weight-only PBs
- Streak reinforcement section

All content must be data-driven.  
PBs are **weight increases only**.
