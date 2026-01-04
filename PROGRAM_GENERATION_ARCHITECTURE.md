# Program Generation Architecture

## Two Methods

### 1. Database-Driven Generation (Primary)

**File:** `trAInSwift/Services/DynamicProgramGenerator.swift`

**How it works:**
- Queries the exercise database (`exercises.db`) to find exercises
- Filters based on your equipment, experience, injuries, and goals
- Uses templates as "blueprints" that say what muscle groups to target

**Templates are blueprints:**
- Example: "3-day Push/Pull/Legs needs: 2 chest, 2 shoulders, 1 triceps on Push day"
- Then it finds actual exercises from the database that match those requirements

**Supports:** 1, 2, 3, 4, 5, 6 days per week

**Pros:**
- Fully personalized
- Shows warnings if equipment is missing
- Respects injuries and contraindications

**Cons:**
- Fails if database is corrupted or missing

---

### 2. Hardcoded Fallback (Backup)

**File:** `trAInSwift/Services/HardcodedPrograms.swift`

**How it works:**
- Pre-written workout programs with specific exercises already chosen
- Like a printed workout plan - every exercise, set, rep, and rest period is fixed

**Templates are complete programs:**
- Example: "3-day PPL = Bench Press 3x8-10, Incline Press 3x8-10, Overhead Press 3x8-10..."
- All exercises are hardcoded, no customization

**Supports:** 2, 3, 4, 5 days per week (⚠️ missing 1 and 6 days)

**Pros:**
- Always works even if database fails
- Reliable safety net

**Cons:**
- Not personalized
- Assumes you have all gym equipment
- Missing 1-day and 6-day programs

---

## The Flow

```
User completes questionnaire
         ↓
Try: Database-Driven Generation
         ↓
    SUCCESS → Personalized program with warnings
         ↓
    FAILURE (database error)
         ↓
Fallback: Hardcoded Program
         ↓
    Generic program (no personalization)
```

---

## The Problem

**Database templates:** Shopping lists ("get me 2 chest exercises")
**Hardcoded templates:** Meal kits ("here's chicken, rice, and broccoli")

- Database has 1-6 day "shopping lists"
- Hardcoded only has 2-5 day "meal kits"
- If database fails and user wants 1 or 6 days → they get a 3-day program instead (wrong!)

---

## Supported Configurations

| Days/Week | Database-Driven | Hardcoded Fallback |
|-----------|-----------------|-------------------|
| 1 day | ✅ Full Body | ❌ **Missing** → Returns 3-day |
| 2 days | ✅ Full Body / Upper-Lower | ✅ Upper-Lower / Full Body |
| 3 days | ✅ Push/Pull/Legs | ✅ Push/Pull/Legs |
| 4 days | ✅ Upper/Lower | ✅ Upper/Lower |
| 5 days | ✅ Custom 5-day | ✅ PPL + Upper + Lower |
| 6 days | ✅ PPL x2 | ❌ **Missing** → Returns 3-day |

---

## File Reference

| File | What It Does |
|------|--------------|
| `ProgramGenerator.swift` | Main entry point - tries database first, falls back to hardcoded if needed |
| `DynamicProgramGenerator.swift` | Database-driven generation with personalization |
| `HardcodedPrograms.swift` | Static backup programs (2-5 days only) |
| `exercises.db` | SQLite database with exercise library |

---

## For MVP TestFlight

**Recommendation:** Add 1-day and 6-day hardcoded programs to match the database-driven system's capabilities.

**Why:** If the database fails for users who selected 1 or 6 days, they'll silently get a 3-day program instead of what they asked for.
