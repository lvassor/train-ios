# TrAIn Database Architecture Audit Report

**Date:** January 17, 2025
**Audit Scope:** Complete database generation and usage pipeline across Python and Swift codebases

## Executive Summary

The current database architecture for TrAIn's exercise system has evolved into a **fragmented, multi-layered system with significant redundancies and potential failure points**. The audit reveals:

### Critical Issues Identified:
1. **Multiple Data Models** - Legacy CSV-based and modern SQLite-based systems coexist
2. **Duplicate Database Files** - Same SQLite database exists in 2 locations
3. **Cross-Language Mapping Inconsistencies** - Equipment mapping differs between Python simulation and Swift app
4. **Schema Migration Incompleteness** - Old CSV models still referenced throughout Swift codebase
5. **Potential Data Sync Issues** - Manual process for updating Excel → Python → Swift pipeline

## Current Architecture Analysis

### 📊 Data Sources & Flow

```
Excel Files (Google Sheets)
    ↓
Python Scripts (database-management/)
    ↓
SQLite Database (exercises.db)
    ↓
Swift App (GRDB + Legacy CSV models)
    ↓
Python Simulator (reads same SQLite)
```

### 🗂️ File Inventory

#### Source Data Files:
- `train_exercise_database_prod.xlsx` (66,386 bytes) - Primary exercise database
- `train_exercise_database_prod_archive.xlsx` (33,891 bytes) - Archived version
- `train_exercise_contraindications_prod.xlsx` (10,158 bytes) - Injury contraindications
- `exercise_video_mapping.csv` (12,750 bytes) - Video URL mappings

#### Generated Database Files:
- `database-management/exercises.db` (126,976 bytes) - Source SQLite database
- `trAInSwift/Resources/exercises.db` (126,976 bytes) - **DUPLICATE** - Copied for iOS app

#### Python Components:
- `create_database_prod.py` (13,677 bytes) - Database generation script
- `simulation/simulate.py` + supporting files - Monte Carlo simulation system
- Equipment mapping constants hardcoded in Python

#### Swift Components:
- `DatabaseModels.swift` - **MODERN** SQLite-based models (DBExercise)
- `ExerciseDatabase.swift` - **LEGACY** CSV-based models (ExerciseDBEntry)
- `ExerciseDatabaseManager.swift` - SQLite GRDB manager
- `ExerciseDatabaseService.swift` - Legacy CSV-based service
- `CSVParser.swift` - Legacy CSV parser

## 🚨 Critical Redundancies & Issues

### 1. Dual Data Model System
**Problem:** Two parallel exercise model systems exist:

- **Legacy System:** `ExerciseDBEntry` + `ExerciseDatabaseService` (CSV-based)
- **Modern System:** `DBExercise` + `ExerciseDatabaseManager` (SQLite-based)

**Impact:**
- Code complexity and maintenance burden
- Potential for data inconsistencies
- 18 references to legacy system vs 70+ references to modern system

### 2. Equipment Mapping Inconsistencies
**Python Simulation Constants:**
```python
EQUIPMENT_OPTIONS = ['Barbells', 'Dumbbells', 'Kettlebells', 'Cables',
                     'Pin-Loaded Machines', 'Plate-Loaded Machines', 'Other']
```

**Swift Questionnaire Mapping:**
```swift
case "dumbbells": dbEquipment.append("Dumbbells")
case "barbells": dbEquipment.append("Barbells")
case "cable_machines": dbEquipment.append("Cables")
// ... etc
```

**Issue:** Hard-coded mappings in multiple languages create sync dependencies.

### 3. Schema Evolution Challenges
**Database Schema (NEW):**
- `complexity_level` as TEXT ("all", "1", "2")
- `canonical_rating` for MCV heuristic
- `equipment_category` + `equipment_specific` hierarchy

**Legacy Models Still Reference:**
- Integer complexity levels
- CSV column names ("Exercise_ID", "Base_Exercise_Name")
- Different field mappings

### 4. Database File Duplication
- Source: `database-management/exercises.db`
- Copy: `trAInSwift/Resources/exercises.db`
- **Risk:** Manual sync process; potential for version mismatches

### 5. Cross-Platform Validation Issues
**Python Simulator** uses different model structure than **Swift App**:
- Python: `Exercise` dataclass with `is_isolation` boolean
- Swift: `DBExercise` with `canonical_rating` scoring system

## 📋 Detailed Findings

### Database Generation Pipeline
✅ **Working Well:**
- `create_database_prod.py` successfully creates SQLite database
- Handles Excel sheet parsing and data transformation
- Includes comprehensive validation and verification
- Auto-copies database to iOS Resources folder

⚠️ **Concerns:**
- Manual Excel file dependency (Google Sheets sync required)
- Hardcoded column mappings could break on Excel changes
- No automated testing of generated database integrity

### Swift Implementation
✅ **Working Well:**
- Modern GRDB-based `ExerciseDatabaseManager` is robust
- Comprehensive `DatabaseModels.swift` with proper type safety
- Equipment hierarchy support for expandable questionnaire
- MCV heuristic algorithm implementation

⚠️ **Legacy Code Issues:**
- `ExerciseDatabase.swift` still contains CSV-based models
- `CSVParser.swift` appears unused but still present
- 18 references to legacy `ExerciseDBEntry` models remain
- Potential confusion between old and new systems

### Python Simulation
✅ **Working Well:**
- Comprehensive Monte Carlo simulation framework
- Direct SQLite database reading for consistency
- Detailed scoring and validation logic

⚠️ **Mapping Inconsistencies:**
- Equipment mappings hardcoded differently than Swift
- Exercise model structure differs from Swift (uses `is_isolation` vs `canonical_rating`)
- Simulation might not perfectly reflect actual app behavior

## 🎯 Recommended Redesign Strategy

### Phase 1: Consolidation (High Priority)

#### 1.1 Remove Legacy Swift Code
- **Delete:** `trAInSwift/Models/ExerciseDatabase.swift`
- **Delete:** `trAInSwift/Services/ExerciseDatabaseService.swift`
- **Delete:** `trAInSwift/Services/CSVParser.swift`
- **Update:** All references to use modern `DBExercise` models only

#### 1.2 Centralize Equipment Mappings
**Create:** `database-management/constants.json`
```json
{
  "equipment_mappings": {
    "dumbbells": "Dumbbells",
    "barbells": "Barbells",
    "cable_machines": "Cables",
    "kettlebells": "Kettlebells",
    "pin_loaded": "Pin-Loaded Machines",
    "plate_loaded": "Plate-Loaded Machines",
    "bodyweight": "Other",
    "other": "Other"
  },
  "equipment_categories": ["Barbells", "Dumbbells", "Kettlebells", "Cables", "Pin-Loaded Machines", "Plate-Loaded Machines", "Other"],
  "experience_levels": ["NO_EXPERIENCE", "BEGINNER", "INTERMEDIATE", "ADVANCED"],
  "complexity_levels": ["all", "1", "2"]
}
```

**Benefits:**
- Single source of truth for all mappings
- Used by both Python scripts and Swift code generation
- Easy to maintain and validate

### Phase 2: Streamlined Pipeline (Medium Priority)

#### 2.1 Enhanced Database Generation
**Improve:** `create_database_prod.py`
- Load constants from `constants.json`
- Add automated schema validation
- Generate Swift enums/constants file
- Implement database versioning

#### 2.2 Automated Code Generation
**Create:** `generate_swift_models.py`
```python
# Reads constants.json + database schema
# Generates Swift enums for equipment, experience levels
# Updates DatabaseModels.swift with latest mappings
# Ensures 100% consistency between Python and Swift
```

#### 2.3 Single Database Location
- Keep database generation in `database-management/`
- Update iOS build process to copy from source location
- Remove duplicate database file from `Resources/`
- Add build script to ensure latest database is used

### Phase 3: Enhanced Validation (Lower Priority)

#### 3.1 Cross-Platform Testing
**Create:** `test_database_consistency.py`
- Validates database schema matches documentation
- Tests equipment mappings across all systems
- Ensures Python simulator and Swift app use identical logic
- Automated test that runs on database changes

#### 3.2 Excel Integration Improvements
- Add Excel format validation before import
- Automated Google Sheets sync (if desired)
- Column mapping validation to prevent silent failures
- Backup/rollback capability for database changes

## 🔧 Implementation Priority

### Immediate (Week 1):
1. **Remove legacy Swift code** - Eliminates confusion and reduces maintenance
2. **Create constants.json** - Centralizes all mappings
3. **Update Python simulator** - Use centralized constants

### Short-term (Week 2-3):
1. **Enhanced database generation script** - Load from constants.json
2. **Single database location** - Remove duplication
3. **Swift constants generation** - Automated consistency

### Medium-term (Month 1):
1. **Automated testing suite** - Ensure consistency
2. **Build process integration** - Seamless database updates
3. **Documentation updates** - Reflect new architecture

## 💡 Additional Recommendations

### Code Organization
- **Move** `database-management/` to `tools/database/` for clarity
- **Create** `tools/database/constants.json` as single source of truth
- **Add** `tools/database/generate_swift_constants.py` for automation

### Error Prevention
- **Schema versioning** in SQLite database to detect mismatches
- **Build-time validation** that ensures database is current
- **Unit tests** for all equipment/experience level mappings

### Future Extensibility
- **Plugin architecture** for adding new equipment types
- **JSON-based exercise templates** for easier programme customization
- **API integration** for remote database updates

## 🎯 Success Metrics

After implementing the recommended changes:

✅ **Zero duplicate data models** - Only `DBExercise` used throughout Swift
✅ **Single source of truth** - All constants in `constants.json`
✅ **100% mapping consistency** - Python and Swift use identical logic
✅ **Automated validation** - Tests ensure database integrity
✅ **Simplified maintenance** - Changes in one location propagate everywhere
✅ **Reduced failure points** - Eliminate manual sync processes

## Conclusion

The current system works but is brittle and maintenance-intensive. The recommended redesign will create a **robust, maintainable, and extensible architecture** that scales with your app's growth while eliminating current pain points and failure modes.

**Estimated Implementation Time:** 2-3 weeks
**Risk Level:** Low (incremental improvements, no breaking changes to user experience)
**Impact:** High (significantly improved maintainability and reliability)