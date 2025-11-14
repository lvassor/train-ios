# trAInSwift

AI-powered personalized fitness training app for iOS.

---

## Overview

trAInSwift generates customized workout programs based on user goals, experience level, available equipment, and injury history. Built with Swift/SwiftUI and powered by Supabase.

---

## Tech Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Backend**: Supabase (Authentication, Database)
- **Local Database**: SQLite (GRDB) - 500+ exercise library
- **Architecture**: MVVM
- **iOS Version**: 17.0+

---

## Quick Start

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Supabase account

### Setup

1. **Clone and navigate:**
   ```bash
   git clone <repository-url>
   cd trAInSwift
   ```

2. **Configure Supabase:**
   - Copy `trAInSwift/Services/Config.swift.example` to `Config.swift`
   - Add your Supabase URL and anon key

3. **Build & Run:**
   ```bash
   open trAInSwift.xcodeproj
   ```
   Press **⌘R** to build and run

### Test Accounts (DEBUG only)
- `test@test.com` / `password123`
- `demo@train.com` / `demo123`
- `user@example.com` / `user123`

---

## Project Structure

```
trAInSwift/
├── Models/              # Data models
├── Views/               # SwiftUI screens
├── ViewModels/          # View state management
├── Services/            # Supabase client, business logic
├── Components/          # Reusable UI components
├── Utilities/           # Helper utilities
├── Resources/           # Exercise database, assets
├── Persistence/         # Core Data layer
└── Assets.xcassets/     # App icons, images
```

---

## Key Features

- **Dynamic Program Generation** - Personalized workout plans with injury contraindications
- **Onboarding Questionnaire** - 10-step flow (gender, age, goals, experience, equipment)
- **Workout Logging** - Track sets, reps, weight with rest timer
- **Progress Tracking** - Session completion, program progress
- **Exercise Library** - Browse 500+ exercises with filters
- **Secure Authentication** - Supabase Auth with keychain storage

---

## Database

### Exercise Database (SQLite)
- **Location**: `trAInSwift/Resources/exercises.db`
- **Size**: 500+ exercises
- **Management**: Python scripts in `database-management/`
- **Features**: Injury contraindications, experience filtering, equipment-based selection

### Core Data Entities
- `UserProfile` - User account data
- `WorkoutProgram` - Generated programs
- `CDWorkoutSession` - Completed workouts

---

## Development

### Code Quality Standards
- ✅ Unified logging with OSLog
- ✅ No force unwraps in critical paths
- ✅ Test accounts gated with `#if DEBUG`
- ✅ Privacy-compliant logging (no PII)

### Before Committing
1. Build succeeds with no warnings
2. No new force unwraps added
3. Test on simulator
4. Test accounts remain in DEBUG blocks

---

## Documentation

- [App Specification](Documentation/app-specification.md) - Feature specifications
- [Database Management](database-management/README.md) - Exercise database tools

---

## License

Proprietary - All rights reserved

---

**Last Updated**: November 14, 2024
