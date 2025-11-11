# TrainSwift

**AI-Powered Personalized Fitness Training App**

An iOS fitness app that generates personalized workout programs based on user goals, experience, equipment availability, and injury history.

---

## Quick Start

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation
```bash
git clone <repository-url>
cd trAInSwift
open trAInSwift.xcodeproj
```

### Test Accounts (DEBUG builds only)
- `test@test.com` / `password123`
- `demo@train.com` / `demo123`
- `user@example.com` / `user123`

### Build & Run
1. Select scheme: **trAInSwift**
2. Select target: **iPhone Simulator**
3. Press **⌘R** to build and run

---

## Architecture

### Tech Stack
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Data Persistence**: Core Data + Keychain
- **Exercise Database**: SQLite (GRDB)
- **Architecture Pattern**: MVVM

### Project Structure
```
trAInSwift/
├── Components/          # Reusable UI components
├── Models/              # Data models
├── Services/            # Business logic & APIs
├── Views/               # SwiftUI screens
├── ViewModels/          # View state management
├── Persistence/         # Core Data layer
├── Utilities/           # Helper utilities
└── Resources/           # Assets, database files
```

---

## Key Features

### ✅ Implemented
- **Dynamic Program Generation** - SQLite-based exercise selection with injury contraindications
- **Personalized Questionnaire** - 10-step onboarding (gender, age, goals, experience, equipment)
- **Workout Logging** - Track sets, reps, weight with rest timer
- **Progress Tracking** - Weekly session completion, program progress
- **Exercise Library** - Browse 500+ exercises with filters
- **Core Data Persistence** - User profiles, programs, workout history
- **Secure Authentication** - Keychain password storage

### 🚧 In Progress
- Exercise video library
- Progress charts & analytics
- Milestone tracking

---

## Development

### Code Quality
- ✅ Unified logging with OSLog
- ✅ No force unwraps in critical paths
- ✅ Test accounts properly gated (#if DEBUG)
- ✅ Privacy-compliant logging (no PII)

### Recent Optimizations
See [OPTIMIZATION_SUMMARY.md](OPTIMIZATION_SUMMARY.md) for details on recent improvements.

### Build Status
```
Configuration: Debug
Platform: iOS Simulator
Status: ✅ BUILD SUCCEEDED
Warnings: 0
Errors: 0
```

---

## Documentation

- **[Quick Start Guide](QUICK_START.md)** - Get started quickly
- **[Optimization Summary](OPTIMIZATION_SUMMARY.md)** - Recent code improvements
- **[Database Management](database-management/README.md)** - Exercise database info

### Archived Documentation
Historical implementation docs are in `Documentation/Archive/`:
- Database Integration details
- Migration notes
- Flowchart comparisons
- Build verification logs

---

## Database

### Exercise Database (SQLite)
- **Location**: `trAInSwift/Resources/exercises.db`
- **Exercises**: 500+ exercises
- **Management**: Python scripts in `database-management/`
- **Features**:
  - Injury contraindications
  - Experience level filtering
  - Equipment-based selection
  - Movement pattern categorization

### Core Data Entities
- `UserProfile` - User account data
- `WorkoutProgram` - Generated programs
- `CDWorkoutSession` - Completed workouts

---

## Contributing

### Code Style
- Follow Swift naming conventions
- Use SwiftUI best practices
- Add documentation comments for public APIs
- Use structured logging (AppLogger) instead of print()

### Before Committing
1. Ensure build succeeds
2. No force unwraps added
3. Test accounts remain in #if DEBUG blocks
4. Run on simulator to verify functionality

---

## License

Proprietary - All rights reserved

---

## Contact

For questions or support, contact the development team.

---

**Last Updated**: November 11, 2025
