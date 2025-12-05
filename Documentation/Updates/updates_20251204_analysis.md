# Task Analysis & Implementation Report — December 4, 2025

---

## Task 1: Data Architecture Analysis & Recommendation

### Current Data Model Assessment

The app uses a **hybrid architecture**:

1. **Core Data** (SQLite under the hood) for user data:
   - `UserProfile` - User info, questionnaire data, arrays (equipment, injuries, muscles)
   - `WorkoutProgram` - Generated programs with exercises stored as JSON in Binary field
   - `CDWorkoutSession` - Completed workout sessions with logged data as JSON
   - `QuestionnaireResponse` - Questionnaire history

2. **SQLite (GRDB)** for read-only exercise library:
   - `exercises` - 143+ exercises with attributes
   - `exercise_contraindications` - Injury-to-exercise mappings
   - `user_experience_complexity` - Experience level rules

### Data Flow Summary

```
User Onboarding:
QuestionnaireView → QuestionnaireData (in-memory) → UserProfile.questionnaireData (JSON Binary)

Program Generation:
QuestionnaireData → DynamicProgramGenerator → ExerciseRepository (SQLite queries) → Program → WorkoutProgram.exercisesData (JSON Binary)

Workout Logging:
ExerciseLoggerView → LoggedExercise/LoggedSet (in-memory) → CDWorkoutSession.exercisesData (JSON Binary)
```

### Current Schema (Core Data)

| Entity | Key Attributes | Storage Method |
|--------|---------------|----------------|
| UserProfile | id, email, age, height, weight, equipment, injuries, priorityMuscles | Transformable arrays |
| WorkoutProgram | id, userId, split, daysPerWeek, exercisesData, completedSessionsData | JSON Binary |
| CDWorkoutSession | id, userId, programId, sessionName, completedAt, exercisesData | JSON Binary |

### Recommended Schema for Cloud Migration (Supabase/PostgreSQL)

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    age INTEGER,
    height_cm DECIMAL(5,1),
    weight_kg DECIMAL(5,1),
    gender VARCHAR(20),
    experience_level VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP
);

-- User equipment (many-to-many)
CREATE TABLE user_equipment (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    equipment_type VARCHAR(100) NOT NULL,
    PRIMARY KEY (user_id, equipment_type)
);

-- User injuries
CREATE TABLE user_injuries (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    injury_type VARCHAR(100) NOT NULL,
    is_healed BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (user_id, injury_type)
);

-- User priority muscles
CREATE TABLE user_priority_muscles (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    muscle_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (user_id, muscle_name)
);

-- Workout programs
CREATE TABLE workout_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    split_type VARCHAR(50),
    days_per_week INTEGER,
    session_duration VARCHAR(20),
    total_weeks INTEGER DEFAULT 8,
    current_week INTEGER DEFAULT 1,
    current_session_index INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Program sessions (normalized from JSON)
CREATE TABLE program_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID REFERENCES workout_programs(id) ON DELETE CASCADE,
    session_index INTEGER NOT NULL,
    day_name VARCHAR(50) NOT NULL,
    UNIQUE (program_id, session_index)
);

-- Program exercises (normalized from JSON)
CREATE TABLE program_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES program_sessions(id) ON DELETE CASCADE,
    exercise_order INTEGER NOT NULL,
    exercise_id INTEGER REFERENCES exercises(exercise_id),
    sets INTEGER NOT NULL,
    rep_range VARCHAR(20),
    rest_seconds INTEGER,
    UNIQUE (session_id, exercise_order)
);

-- Completed workout sessions
CREATE TABLE workout_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    program_id UUID REFERENCES workout_programs(id) ON DELETE SET NULL,
    session_name VARCHAR(50),
    week_number INTEGER,
    completed_at TIMESTAMP DEFAULT NOW(),
    duration_seconds INTEGER,
    notes TEXT
);

-- Logged exercises (normalized from JSON)
CREATE TABLE logged_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES workout_sessions(id) ON DELETE CASCADE,
    exercise_id INTEGER REFERENCES exercises(exercise_id),
    exercise_name VARCHAR(255),
    notes TEXT,
    exercise_order INTEGER
);

-- Logged sets (normalized from JSON)
CREATE TABLE logged_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    logged_exercise_id UUID REFERENCES logged_exercises(id) ON DELETE CASCADE,
    set_number INTEGER NOT NULL,
    reps INTEGER,
    weight_kg DECIMAL(6,2),
    completed BOOLEAN DEFAULT FALSE
);
```

### Recommendation: Relational (PostgreSQL/Supabase)

**Justification:**
1. **Structured data** - Workout logs have predictable schema (sets/reps/weight)
2. **Query flexibility** - Need to query "all times user did exercise X" for progression
3. **Referential integrity** - Exercise IDs must reference valid exercises
4. **Analytics** - SQL aggregations for PRs, volume, trends
5. **Supabase fit** - Built on PostgreSQL, excellent iOS SDK, row-level security

**Not NoSQL because:**
- Data isn't deeply nested or schema-less
- Strong relationships between entities
- Need JOIN queries for analytics
- Don't need horizontal scaling at MVP

### Android Compatibility Considerations

1. **Use Supabase SDKs** - Available for both iOS (Swift) and Android (Kotlin)
2. **Share schema** - PostgreSQL is platform-agnostic
3. **Avoid platform-specific patterns** - No Core Data on Android
4. **JSON responses** - Both platforms parse JSON identically
5. **UUID primary keys** - Work everywhere (vs auto-increment)

### Session Notes Feature (New)

Add to `workout_sessions` table:
```sql
notes TEXT  -- Already included in recommended schema above
```

In Core Data MVP, add to `CDWorkoutSession`:
```swift
@NSManaged public var notes: String?
```

---

## Task 2: Exercise Database SQL Schema Update

### Current Schema Issues

1. `movement_pattern` field doesn't match new data (should be `canonical_name`)
2. Missing `equipment_name` field (e.g., "Leg Press", "Hack Squat")
3. Missing `equipment_type` field (Pin-Loaded, Plate-Loaded, Cable)
4. Missing `accessory_equipment` field
5. Complexity allows "iso" string but schema enforces INTEGER

### New SQL Schema

```sql
-- Drop existing tables
DROP TABLE IF EXISTS exercise_contraindications;
DROP TABLE IF EXISTS exercises;

-- Main exercises table
CREATE TABLE exercises (
    exercise_id TEXT PRIMARY KEY,           -- e.g., "EX001"
    canonical_name TEXT NOT NULL,           -- Movement pattern grouping for swaps
    display_name TEXT NOT NULL,             -- User-facing name
    equipment_name TEXT NOT NULL,           -- e.g., "Barbell", "Leg Press", "Hack Squat"
    equipment_type TEXT,                    -- "Pin-Loaded", "Plate-Loaded", "Cable", NULL
    accessory_equipment TEXT,               -- e.g., "Cable Attachment", "Adjustable Bench"
    complexity_level TEXT NOT NULL,         -- "1", "2", "3", "4", "iso"
    primary_muscle TEXT NOT NULL,
    secondary_muscle TEXT,
    instructions TEXT,
    is_active INTEGER NOT NULL DEFAULT 1
);

-- Indexes for filtering
CREATE INDEX idx_exercises_canonical ON exercises(canonical_name);
CREATE INDEX idx_exercises_equipment_name ON exercises(equipment_name);
CREATE INDEX idx_exercises_equipment_type ON exercises(equipment_type);
CREATE INDEX idx_exercises_complexity ON exercises(complexity_level);
CREATE INDEX idx_exercises_primary_muscle ON exercises(primary_muscle);
CREATE INDEX idx_exercises_active ON exercises(is_active);

-- Contraindications table (unchanged structure)
CREATE TABLE exercise_contraindications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    exercise_id TEXT NOT NULL,
    injury_type TEXT NOT NULL,
    FOREIGN KEY (exercise_id) REFERENCES exercises(exercise_id) ON DELETE CASCADE,
    UNIQUE(exercise_id, injury_type)
);

CREATE INDEX idx_contraindications_exercise ON exercise_contraindications(exercise_id);
CREATE INDEX idx_contraindications_injury ON exercise_contraindications(injury_type);

-- Experience complexity rules (unchanged)
CREATE TABLE user_experience_complexity (
    experience_level TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    max_complexity INTEGER NOT NULL,
    max_complexity_4_per_session INTEGER NOT NULL,
    complexity_4_must_be_first INTEGER NOT NULL
);

-- Seed experience data
INSERT INTO user_experience_complexity VALUES
    ('BEGINNER', 'Beginner', 2, 0, 0),
    ('INTERMEDIATE', 'Intermediate', 3, 0, 0),
    ('ADVANCED', 'Advanced', 4, 1, 1);
```

### Migration Notes

1. Export CSV from Excel `total_db` sheet
2. Change `exercise_id` from INTEGER to TEXT (e.g., "EX001")
3. Map `movement_pattern` → `canonical_name`
4. Add new fields: `equipment_name`, `equipment_type`, `accessory_equipment`
5. Change `complexity_level` from INTEGER to TEXT to support "iso"
6. Update `DatabaseModels.swift` to match new schema
7. Update `ExerciseDatabaseManager.swift` for new queries

---

## Task 3: Experience Level Question Redesign

### Current → New Mapping

| Old Value | Old Display | New Title | New Subtitle | Complexity |
|-----------|------------|-----------|--------------|------------|
| `0_months` | "Complete beginner" | **Just Starting Out** | "New to the gym or never tried strength training? Perfect — we'll guide you through the fundamentals with exercises that build confidence." | max=2 |
| `0_6_months` | "0-6 months" | **Finding My Feet** | "You've tried a few things but still figuring it out? We'll give you a solid foundation with straightforward movements." | max=2 |
| `6_months_2_years` | "6 months - 2 years" | **Getting Comfortable** | "You know your way around the gym and feel fairly confident with the basics. We'll build on that with some variety." | max=3 |
| `2_plus_years` | "2+ years" | **Confident & Consistent** | "You train regularly and feel confident with most exercises. We'll challenge you with the full range of movements." | max=4 |

### Implementation Changes

Update `QuestionnaireSteps.swift`:

```swift
let experiences = [
    ("0_months", "Just Starting Out", "New to the gym or never tried strength training? Perfect — we'll guide you through the fundamentals with exercises that build confidence."),
    ("0_6_months", "Finding My Feet", "You've tried a few things but still figuring it out? We'll give you a solid foundation with straightforward movements."),
    ("6_months_2_years", "Getting Comfortable", "You know your way around the gym and feel fairly confident with the basics. We'll build on that with some variety."),
    ("2_plus_years", "Confident & Consistent", "You train regularly and feel confident with most exercises. We'll challenge you with the full range of movements.")
]
```

---

## Task 4: Equipment Availability — Expandable Detail

### Equipment Categories from Database

**Barbells** (accessory-based expansion):
- Squat Rack
- Flat Bench Press
- Incline Bench Press
- Decline Bench Press
- Landmine

**Pin-Loaded Machines** (`equipment_type = 'Pin-Loaded'`):
- Leg Press (Pin-Loaded)
- Leg Extension
- Lying Leg Curl
- Seated Leg Curl
- Standing Calf Raise
- Seated Calf Raise
- Hip Abduction
- Hip Adduction
- Lat Pulldown
- Seated Row
- Chest Press Machine
- Pec Deck

**Plate-Loaded Machines** (`equipment_type = 'Plate-Loaded'`):
- Leg Press (Plate-Loaded)
- Hack Squat
- Leg Extension (Plate-Loaded)
- Lying Leg Curl (Plate-Loaded)
- Standing Calf Raise (Plate-Loaded)
- T-Bar Row
- Chest Supported Row

### Implementation Approach

See implementation in `QuestionnaireSteps.swift` ExpandableEquipmentCard component.

---

## Task 5: Rest Timer UX Redesign

### Current: Full-screen overlay blocking interaction
### New: Inline timer in exercise card

See implementation in `ExerciseLoggerView.swift` InlineRestTimer component.

---

## Task 6: Bug Fix — Number Pad Dismissal

### Solution: Add Done button toolbar

```swift
.toolbar {
    ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
```

---

## Task 7: Charcoal Gradient Background Fix

### Current Implementation Analysis

The gradient is defined in `Theme.swift` and `ColorPalette.swift`:
- `gradientLight = "#5E5E5E"` (medium gray)
- `gradientMid = "#101010"` (dark gray)
- `gradientDark = "#0B0B0B"` (near black)

Applied via `.warmDarkGradientBackground()` modifier.

### Issue: Many views don't use the modifier

Need to audit all views and ensure gradient is applied.

---

## Complexity Estimates

| Task | Complexity | Estimate |
|------|-----------|----------|
| Task 1 | High | Analysis complete |
| Task 2 | Medium | 2 hours (schema + migration) |
| Task 3 | Low | 30 mins (copy changes) |
| Task 4 | High | 3-4 hours (new UI component) |
| Task 5 | Medium | 2 hours (new inline timer) |
| Task 6 | Low | 15 mins (toolbar modifier) |
| Task 7 | Medium | 1-2 hours (audit + apply) |

---

## Technical Debt Identified

1. **JSON serialization overhead** - Program/session data parsed on every access
2. **No exercise history index** - Progression queries require parsing all sessions
3. **Complexity-4 rules scattered** - Business logic in multiple files
4. **Empty session risk** - No validation prevents empty workout sessions
5. **Fallback removes injury filters** - Could prescribe contraindicated exercises
