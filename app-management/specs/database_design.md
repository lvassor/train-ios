# TrAIn Database Architecture Design v2.0

**Version:** 2.0.0
**Last Updated:** January 18, 2025
**Status:** Production Ready

## Executive Summary

This document describes the redesigned database architecture for TrAIn's exercise and program generation system. The new architecture eliminates redundancies, centralizes constants, and provides seamless video integration with bunny.net.

## Architecture Overview

### 🎯 Core Principles
1. **Single Source of Truth** - All constants and mappings centralized
2. **No Duplication** - Database generated directly in final location
3. **Cross-Platform Consistency** - Python and Swift use identical logic
4. **Video-First Design** - Built-in support for bunny.net streaming
5. **Future-Proof Schema** - Extensible design for new features

### 📊 Data Flow Pipeline

```
Excel Files (Google Sheets)
    ↓
constants.json (mappings)
    ↓
Python Script (create_database_prod.py)
    ↓
SQLite Database (trAInSwift/Resources/exercises.db)
    ↓
Swift App (GRDB models) ←→ Python Simulator (validation)
```

## Database Schema

### Core Tables

#### 1. `exercises` Table
**Purpose:** Core exercise data with MCV heuristic support

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `exercise_id` | TEXT | PRIMARY KEY | Unique identifier (e.g., "EX001") |
| `canonical_name` | TEXT | NOT NULL | Movement pattern grouping (e.g., "Bench Press") |
| `display_name` | TEXT | NOT NULL | User-facing name (e.g., "Barbell Flat Bench Press") |
| `equipment_category` | TEXT | NOT NULL | High-level equipment (e.g., "Barbells", "Dumbbells") |
| `equipment_specific` | TEXT | NULLABLE | Specific equipment (e.g., "Squat Rack", "Flat Bench") |
| `complexity_level` | TEXT | NOT NULL | Exercise complexity: "all", "1", "2" |
| `primary_muscle` | TEXT | NOT NULL | Main muscle group targeted |
| `secondary_muscle` | TEXT | NULLABLE | Optional secondary muscle |
| `instructions` | TEXT | NULLABLE | Exercise instructions |
| `is_in_programme` | INTEGER | NOT NULL, DEFAULT 1 | Include in programme generation (0/1) |
| `canonical_rating` | INTEGER | NOT NULL, DEFAULT 50 | MCV heuristic score (0-100) |
| `progression_id` | TEXT | NULLABLE | Comma-separated exercise_ids for progressions |
| `regression_id` | TEXT | NULLABLE | Comma-separated exercise_ids for regressions |

**Key Features:**
- MCV heuristic algorithm support via `canonical_rating`
- Equipment hierarchy with category/specific breakdown
- Progressive overload via progression/regression chains

#### 2. `exercise_contraindications` Table
**Purpose:** Links exercises to injury warnings

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique row ID |
| `canonical_name` | TEXT | NOT NULL | Links to exercises.canonical_name |
| `injury_type` | TEXT | NOT NULL | Injury type (e.g., "Back", "Shoulders") |

**Unique Constraint:** `(canonical_name, injury_type)`

**Supported Injury Types:**
- Back, Biceps, Calves, Chest, Core, Forearms
- Glutes, Hamstrings, Quads, Shoulders, Traps, Triceps

#### 3. `exercise_videos` Table ⭐ **NEW**
**Purpose:** Bunny.net video integration for exercise demonstrations

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique row ID |
| `exercise_id` | TEXT | NOT NULL, FOREIGN KEY | Links to exercises.exercise_id |
| `supplier_id` | TEXT | NULLABLE | Video supplier identifier |
| `media_type` | TEXT | NOT NULL | "vid" or "img" |
| `filename` | TEXT | NOT NULL | Original filename |
| `bunny_url` | TEXT | NOT NULL | Full bunny.net CDN URL |
| `note` | TEXT | NULLABLE | Optional notes about the media |

**Features:**
- Pre-generated bunny.net URLs for instant video streaming
- Support for both videos (.mp4) and images (.png, .jpg)
- Supplier tracking for content attribution

### Performance Indexes

**Exercise Table:**
- `idx_exercises_canonical` - Fast canonical name lookups
- `idx_exercises_category` - Equipment category filtering
- `idx_exercises_complexity` - Experience level filtering
- `idx_exercises_muscle` - Muscle group filtering
- `idx_exercises_rating` - MCV heuristic ordering

**Video Table:**
- `idx_videos_exercise_id` - Fast video lookups by exercise
- `idx_videos_media_type` - Media type filtering

## Centralized Constants System

### constants.json Structure

```json
{
  "equipment_mappings": {
    "bodyweight": "Bodyweight",
    "barbells": "Barbells",
    "dumbbells": "Dumbbells",
    "kettlebells": "Kettlebells",
    "cable_machines": "Cables",
    "pin_loaded": "Pin-Loaded Machines",
    "plate_loaded": "Plate-Loaded Machines",
    "other": "Other"
  },
  "equipment_categories": [...],
  "experience_levels": [...],
  "injury_types": [...],
  "video_config": {
    "bunny_base_url": "https://vz-f673c4c2-345.b-cdn.net/",
    "media_types": ["vid", "img"]
  }
}
```

### Cross-Platform Mappings

**Questionnaire (UI) → Database:**
- `"dumbbells"` → `"Dumbbells"`
- `"cable_machines"` → `"Cables"`
- `"bodyweight"` → `"Bodyweight"` ⭐ **NEW**

**Experience Levels:**
- `"no_experience"` → `"NO_EXPERIENCE"`
- Legacy support: `"0_months"` → `"NO_EXPERIENCE"`

## Database Generation Process

### Updated Pipeline

1. **Source Validation**
   - Verify Excel files exist and are readable
   - Load and validate constants.json structure
   - Check video mapping CSV integrity

2. **Database Creation**
   - Generate database DIRECTLY in `trAInSwift/Resources/exercises.db`
   - No intermediate files or copying steps
   - Atomic operations with rollback on failure

3. **Data Import Sequence**
   ```
   exercises (140 records) →
   contraindications (38 records) →
   videos (138 records with bunny URLs)
   ```

4. **Validation & Verification**
   - Schema compliance checks
   - Foreign key validation
   - Sample query testing
   - Size and performance metrics

### File Dependencies

**Input Files:**
- `train_exercise_database_prod.xlsx` (master sheet)
- `train_exercise_contraindications_prod.xlsx` (data sheet)
- `exercise_video_mapping.csv` (video URLs)
- `constants.json` (centralized mappings)

**Output:**
- `trAInSwift/Resources/exercises.db` (164KB, 140 exercises)

## Swift Integration

### GRDB Models

```swift
// Modern SQLite-based models (ONLY)
struct DBExercise: Codable, FetchableRecord, TableRecord { ... }
struct DBExerciseContraindication: Codable, FetchableRecord { ... }
struct DBExerciseVideo: Codable, FetchableRecord { ... } // NEW
```

**Legacy Removed:**
- ❌ `ExerciseDBEntry` (CSV-based)
- ❌ `ExerciseDatabaseService` (CSV-based)
- ❌ `CSVParser` (unused)

### Equipment Mapping Logic

```swift
static func mapEquipmentFromQuestionnaire(_ equipment: [String]) -> [String] {
    // Maps UI selections to database categories
    // Example: ["dumbbells", "bodyweight"] → ["Dumbbells", "Bodyweight"]
}
```

### Video URL Generation

```swift
struct DBExerciseVideo {
    let bunnyUrl: String  // Pre-generated: "https://vz-f673c4c2-345.b-cdn.net/filename.mp4"

    var isVideo: Bool { mediaType == "vid" }
    var isImage: Bool { mediaType == "img" }
}
```

## Python Simulator Integration

### Updated Simulation Constants

```python
# Loaded from constants.json (no hardcoding)
EQUIPMENT_OPTIONS = load_constants()['equipment_categories']
EXPERIENCE_LEVELS = load_constants()['experience_levels']
```

### Cross-Platform Validation

- Equipment mappings: 100% consistent Python ↔ Swift
- Database queries: Identical SQL across platforms
- Algorithm testing: Python simulation validates Swift logic

## Video System Architecture

### Bunny.net Integration

**CDN Configuration:**
- Base URL: `https://vz-f673c4c2-345.b-cdn.net/`
- Formats: MP4 video, PNG/JPG images
- Pre-generated URLs in database for instant access

**Video Coverage:**
- 138/140 exercises have video/image content (98.6% coverage)
- Missing videos handled gracefully with placeholder content

**Integration Points:**
- Workout Logger → Demo tab → Video player
- Exercise Library → Exercise detail → Media display
- Program generation → Exercise selection with media availability

## Migration Notes

### What Changed from v1.0

**✅ Improvements:**
- Single database location (no duplication)
- Centralized constants (no mapping inconsistencies)
- Video integration (bunny.net ready)
- Updated equipment categories (includes Bodyweight)
- Enhanced contraindications (12 injury types)
- Removed legacy code (18 fewer references)

**🔧 Breaking Changes:**
- Equipment mapping now includes "bodyweight" category
- Contraindications use canonical_name (not exercise_id)
- Video table added (new queries needed)

**📋 Compatibility:**
- All existing questionnaire data compatible
- Programme generation logic unchanged
- User experience unchanged (backend improvements only)

## Operational Guidelines

### Database Updates

1. **Modify Excel files** (Google Sheets)
2. **Update constants.json** if mappings change
3. **Run:** `python3 create_database_prod.py`
4. **Verify:** Database created in correct location
5. **Test:** Build and run iOS app

### Adding New Equipment

1. **Add to constants.json:**
   - `equipment_mappings`: UI → DB mapping
   - `equipment_categories`: DB category list

2. **Update Swift:**
   - Equipment hierarchy (if expandable)
   - Questionnaire options

3. **Regenerate database** with new script

### Video Management

**Adding Videos:**
1. Upload to bunny.net CDN
2. Add row to `exercise_video_mapping.csv`
3. Regenerate database
4. Videos automatically available in app

**URL Structure:**
```
Base: https://vz-f673c4c2-345.b-cdn.net/
File: 54711201-Rounded-Back-Extension_Hips_.mp4
URL:  https://vz-f673c4c2-345.b-cdn.net/54711201-Rounded-Back-Extension_Hips_.mp4
```

## Performance Metrics

### Database Size & Performance
- **File Size:** 164KB (optimized for mobile)
- **Exercise Count:** 140 total, 115 for programme generation
- **Query Performance:** <1ms for typical lookups
- **Memory Usage:** ~2MB loaded in RAM

### Coverage Statistics
- **Video Coverage:** 138/140 exercises (98.6%)
- **Contraindications:** 38 mappings across 12 injury types
- **Equipment Support:** 8 categories, 30+ specific items
- **Complexity Distribution:** 69 beginner, 48 intermediate, 23 advanced

## Future Extensibility

### Planned Enhancements
1. **Exercise Variations** - Sub-exercise groupings
2. **Equipment Validation** - Smart equipment checking
3. **Video Analytics** - Usage tracking and optimization
4. **Multi-Language** - Internationalized exercise names
5. **API Integration** - Remote database updates

### Architecture Support
- JSON-based configuration (easily extensible)
- Modular video system (supports multiple CDNs)
- Flexible equipment hierarchy (expandable categories)
- Version-controlled schema (migration support)

---

## Quick Reference

### Key Files
- **Database:** `trAInSwift/Resources/exercises.db`
- **Constants:** `constants.json`
- **Generator:** `create_database_prod.py`
- **Models:** `trAInSwift/Models/DatabaseModels.swift`

### Essential Commands
```bash
# Regenerate database
python3 create_database_prod.py

# Verify database
sqlite3 trAInSwift/Resources/exercises.db ".schema"

# Check video count
sqlite3 trAInSwift/Resources/exercises.db "SELECT COUNT(*) FROM exercise_videos;"
```

### Support
For issues or questions:
1. Check database generation logs
2. Validate constants.json structure
3. Verify Excel file integrity
4. Review Swift build errors

This design ensures a robust, maintainable, and scalable database architecture that supports TrAIn's current needs while providing a strong foundation for future growth.