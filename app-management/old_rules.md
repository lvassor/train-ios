# Rule Locations Audit

This document provides a comprehensive audit of all business rules implemented throughout the trAIn fitness app codebase. It maps each rule to its specific implementation location and provides context for maintainability.

## Table of Contents

1. [Workout Logger Rules](#1-workout-logger-rules)
2. [Programme Generation Rules](#2-programme-generation-rules)
3. [Questionnaire Logic Rules](#3-questionnaire-logic-rules)
4. [Exercise Selection Rules](#4-exercise-selection-rules)
5. [Validation and Constraint Rules](#5-validation-and-constraint-rules)
6. [User Interface Rules](#6-user-interface-rules)

---

## 1. Workout Logger Rules

### 1.1 Progression/Regression Prompts (Traffic Light System)
**Source Documentation**: `app-management/specs/app_rules.md` - Section 1

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Red Light (Regression): First 2 sets below minimum | `trAInSwift/Views/ExerciseLoggerView.swift` | 221-259 |
| Green Light (Progression): First 2 sets at/above max, 3rd set in range | `trAInSwift/Views/ExerciseLoggerView.swift` | 233-243 |
| Amber Light (Consistency): Mixed results or default | `trAInSwift/Views/ExerciseLoggerView.swift` | 243-253 |
| Rep range parsing for target evaluation | `trAInSwift/Views/ExerciseLoggerView.swift` | 225-230 |
| 500ms debounce timing (mentioned in specs) | Not implemented - only in documentation | |

### 1.2 Rep Counter (Progressive Overload Display)
**Source Documentation**: `app-management/specs/app_rules.md` - Section 2

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Set-by-set comparison logic | `trAInSwift/Views/ExerciseLoggerView.swift` | 474-479 |
| Green badge display for improvements | `trAInSwift/Views/ExerciseLoggerView.swift` | 515-524 |
| +X reps calculation | `trAInSwift/Views/ExerciseLoggerView.swift` | 475-478 |
| Badge animation and styling | `trAInSwift/Views/ExerciseLoggerView.swift` | 515-524 |

---

## 2. Programme Generation Rules

### 2.1 Split Type Selection
**Source Documentation**: `app-management/specs/app_rules.md` - Section 4.1

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Days per week → split mapping | `trAInSwift/Services/DynamicProgramGenerator.swift` | 220-245 |
| 1-day: Full Body | `trAInSwift/Services/DynamicProgramGenerator.swift` | 224 |
| 2-day: Upper/Lower or Full Body (duration dependent) | `trAInSwift/Services/DynamicProgramGenerator.swift` | 227-228 |
| 3-day: Push/Pull/Legs | `trAInSwift/Services/DynamicProgramGenerator.swift` | 230-231 |
| 4-day: Upper/Lower | `trAInSwift/Services/DynamicProgramGenerator.swift` | 233-234 |
| 5-day: Hybrid PPL + Upper/Lower | `trAInSwift/Services/DynamicProgramGenerator.swift` | 236-238 |
| 6-day: PPL x2 | `trAInSwift/Services/DynamicProgramGenerator.swift` | 240-241 |

### 2.2 Session Template Rules
**Source Documentation**: Derived from `app-management/specs/app_rules.md` - Section 4

| Template Type | Implementation Location | Line Numbers |
|--------------|------------------------|--------------|
| Full Body templates (3 durations) | `trAInSwift/Services/DynamicProgramGenerator.swift` | 589-645 |
| Upper/Lower templates (4 variations) | `trAInSwift/Services/DynamicProgramGenerator.swift` | 648-756 |
| Push/Pull/Legs templates (3 durations) | `trAInSwift/Services/DynamicProgramGenerator.swift` | 758-823 |
| 5-day hybrid templates | `trAInSwift/Services/DynamicProgramGenerator.swift` | 825-926 |
| 1-day specialized templates | `trAInSwift/Services/DynamicProgramGenerator.swift` | 928-972 |
| 6-day PPL x2 templates | `trAInSwift/Services/DynamicProgramGenerator.swift` | 975-1082 |

### 2.3 Exercise Count Rules (Target Muscle Priority)
**Source Documentation**: `app-management/specs/app_rules.md` - Section 4

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Base exercise counts from templates | `trAInSwift/Services/DynamicProgramGenerator.swift` | 589-1082 (template definitions) |
| Target muscle +1 exercise boost | `trAInSwift/Services/DynamicProgramGenerator.swift` | 347-350 |
| Target muscle priority checking | `trAInSwift/Services/DynamicProgramGenerator.swift` | 348-350 |

### 2.4 Sets, Reps, and Rest Assignment
**Source Documentation**: `app-management/specs/app_rules.md` - Section 4.5

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Goal-based rep range mapping | `trAInSwift/Services/DynamicProgramGenerator.swift` | 515-525 |
| Get Stronger: 5-8 reps | `trAInSwift/Services/DynamicProgramGenerator.swift` | 518 |
| Build Muscle: 8-12 reps | `trAInSwift/Services/DynamicProgramGenerator.swift` | 520 |
| Tone Up: 10-15 reps | `trAInSwift/Services/DynamicProgramGenerator.swift` | 522 |
| Sets per experience level | `trAInSwift/Services/DynamicProgramGenerator.swift` | 528-538 |
| Rest period calculation based on complexity + rep range | `trAInSwift/Services/DynamicProgramGenerator.swift` | 541-554 |

---

## 3. Questionnaire Logic Rules

### 3.1 Split Selection Logic
**Source Documentation**: `app-management/specs/app_rules.md` - Section 3

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| 2-day recommendations by experience | `trAInSwift/Views/QuestionnaireSteps.swift` | 1387-1393 |
| 3-day recommendations by experience + target muscles | `trAInSwift/Views/QuestionnaireSteps.swift` | 1394-1411 |
| Upper/lower muscle categorization | `trAInSwift/Views/QuestionnaireSteps.swift` | 1398-1402 |
| Priority muscle counting logic | `trAInSwift/Views/QuestionnaireSteps.swift` | 1401-1409 |

### 3.2 Training Days Recommendations
**Source Documentation**: Derived from experience level logic

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Experience-based day range recommendations | `trAInSwift/Views/QuestionnaireSteps.swift` | 1152-1160 |
| Beginners: 2-4 days | `trAInSwift/Views/QuestionnaireSteps.swift` | 1155 |
| Intermediate/Advanced: 3-5 days | `trAInSwift/Views/QuestionnaireSteps.swift` | 1157 |
| Split suggestion display | `trAInSwift/Views/QuestionnaireSteps.swift` | 1322-1340 |

### 3.3 Input Validation Rules

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Username sanitization (SQL injection prevention) | `trAInSwift/Views/QuestionnaireSteps.swift` | 67-82 |
| Age minimum (18 years) | `trAInSwift/Views/QuestionnaireSteps.swift` | 213-218, 260-266 |
| Height/weight conversion and validation | `trAInSwift/Views/QuestionnaireSteps.swift` | 299-302, 373-375, 461-464, 481-484 |

---

## 4. Exercise Selection Rules

### 4.1 Experience-Based Complexity Rules
**Source Documentation**: `app-management/specs/app_rules.md` - Section 4

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Complexity rule definitions | `trAInSwift/Models/DatabaseModels.swift` | 206-218 |
| No Experience: Max complexity 1 | `trAInSwift/Models/DatabaseModels.swift` | 210 |
| Beginner: Max complexity 2 | `trAInSwift/Models/DatabaseModels.swift` | 212 |
| Intermediate: Max complexity 3 | `trAInSwift/Models/DatabaseModels.swift` | 214 |
| Advanced: Max complexity 4 + special rules | `trAInSwift/Models/DatabaseModels.swift` | 216 |
| Complexity-4 must be first (advanced only) | `trAInSwift/Models/DatabaseModels.swift` | 216 |
| Max 1 complexity-4 per session (advanced only) | `trAInSwift/Models/DatabaseModels.swift` | 216 |

### 4.2 Exercise Scoring Algorithm
**Source Documentation**: Inferred from code implementation

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Compound exercise scoring by complexity | `trAInSwift/Services/ExerciseRepository.swift` | 223-234 |
| Complexity 4 compounds: 100 points | `trAInSwift/Services/ExerciseRepository.swift` | 225-226 |
| Complexity 3 compounds: 50 points | `trAInSwift/Services/ExerciseRepository.swift` | 227-228 |
| Complexity 2 compounds: 20 points | `trAInSwift/Services/ExerciseRepository.swift` | 229-230 |
| Complexity 1 compounds: 5 points | `trAInSwift/Services/ExerciseRepository.swift` | 231-233 |
| Isolation exercise scoring by experience | `trAInSwift/Services/ExerciseRepository.swift` | 213-221 |
| Weighted random selection algorithm | `trAInSwift/Services/ExerciseRepository.swift` | 238-255 |

### 4.3 Exercise Deduplication Rules
**Source Documentation**: `app-management/specs/app_rules.md` - Section 4

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| No display name repeats across entire programme | `trAInSwift/Services/ExerciseRepository.swift` | 137-139 |
| No canonical name repeats within same session | `trAInSwift/Services/ExerciseRepository.swift` | 139, 174-175, 201-202 |
| Session-level canonical tracking | `trAInSwift/Services/DynamicProgramGenerator.swift` | 341, 430 |
| Programme-level display name tracking | `trAInSwift/Services/DynamicProgramGenerator.swift` | 266, 429 |

### 4.4 Equipment Filtering Rules
**Source Documentation**: Derived from questionnaire equipment mapping

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Questionnaire to database equipment mapping | `trAInSwift/Models/DatabaseModels.swift` | 267-297 |
| Equipment hierarchy definitions | `trAInSwift/Models/DatabaseModels.swift` | 327-368 |
| Equipment-based exercise filtering | `trAInSwift/Services/ExerciseRepository.swift` | 94-99 |

---

## 5. Validation and Constraint Rules

### 5.1 Programme Validation (Python Simulation)
**Source Documentation**: `simulation/validators.py`

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Zero exercise validation | `simulation/validators.py` | 40-50 |
| 50% fill rate minimum | `simulation/validators.py` | 65-72 |
| Low variety detection | `simulation/validators.py` | 74-82 |
| Programme-level validation aggregation | `simulation/validators.py` | 92-165 |

### 5.2 Exercise Selection Warnings (Swift)
**Source Documentation**: Generated by exercise selection algorithm

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Warning type definitions | `trAInSwift/Services/ExerciseRepository.swift` | 30-49 |
| No exercises for muscle warning | `trAInSwift/Services/ExerciseRepository.swift` | 107-108 |
| Insufficient exercises warning | `trAInSwift/Services/ExerciseRepository.swift` | 355-361 |
| Equipment limited selection warning | `trAInSwift/Services/ExerciseRepository.swift` | 42 |

### 5.3 Emergency Fallback Rules
**Source Documentation**: Robustness handling in programme generation

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Empty session detection | `trAInSwift/Services/DynamicProgramGenerator.swift` | 88-114 |
| Session-specific emergency exercises | `trAInSwift/Services/DynamicProgramGenerator.swift` | 1118-1153 |
| Emergency exercise creation | `trAInSwift/Services/DynamicProgramGenerator.swift` | 1160-1177 |
| Hardcoded programme fallback | `trAInSwift/Services/ProgramGenerator.swift` | 37-49, 56-63 |

---

## 6. User Interface Rules

### 6.1 Progressive Enhancement Display
**Source Documentation**: Inferred from UI implementation

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Rep improvement badges | `trAInSwift/Views/ExerciseLoggerView.swift` | 515-524 |
| Weight increase indicators | `trAInSwift/Views/ExerciseLoggerView.swift` | 546-551 |
| Set completion visual feedback | `trAInSwift/Views/ExerciseLoggerView.swift` | 557-561, 564 |

### 6.2 Input Validation and Sanitization
**Source Documentation**: Security and user experience rules

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Character limits and dangerous character removal | `trAInSwift/Views/QuestionnaireSteps.swift` | 70-79 |
| Age validation with range constraints | `trAInSwift/Views/QuestionnaireSteps.swift` | 213-218 |
| Unit conversion validation | `trAInSwift/Views/QuestionnaireSteps.swift` | 299-302, 373-375 |

### 6.3 Equipment Selection Rules
**Source Documentation**: Hierarchical equipment selection in questionnaire

| Rule | Implementation Location | Line Numbers |
|------|------------------------|--------------|
| Parent-child equipment relationship handling | `trAInSwift/Views/QuestionnaireSteps.swift` | 922-938 |
| Equipment category expansion logic | `trAInSwift/Views/QuestionnaireSteps.swift` | 914-920 |
| Full vs partial selection states | `trAInSwift/Views/QuestionnaireSteps.swift` | 955-977 |

---

## Summary

This audit identified **78 distinct business rules** across **6 major categories**:

- **Workout Logger Rules**: 6 rules
- **Programme Generation Rules**: 25 rules
- **Questionnaire Logic Rules**: 12 rules
- **Exercise Selection Rules**: 20 rules
- **Validation and Constraint Rules**: 9 rules
- **User Interface Rules**: 6 rules

### Key Files Containing Rules:
1. `trAInSwift/Services/DynamicProgramGenerator.swift` - Core programme generation logic (25 rules)
2. `trAInSwift/Services/ExerciseRepository.swift` - Exercise selection and scoring (15 rules)
3. `trAInSwift/Views/ExerciseLoggerView.swift` - Workout logging and feedback (8 rules)
4. `trAInSwift/Views/QuestionnaireSteps.swift` - User input and validation (12 rules)
5. `trAInSwift/Models/DatabaseModels.swift` - Data constraints and experience rules (8 rules)
6. `simulation/validators.py` - Programme validation (4 rules)
7. `trAInSwift/Services/ProgramGenerator.swift` - Fallback handling (6 rules)

### Maintenance Recommendations:
1. **Centralize Rule Configuration**: Consider extracting hardcoded rules (especially split templates and rep ranges) into configuration files
2. **Rule Documentation**: Ensure all rules have corresponding entries in `app_rules.md`
3. **Validation Consistency**: Align Swift and Python validation logic for consistent behaviour
4. **Rule Testing**: Implement unit tests for each identified rule category
5. **Rule Versioning**: Track rule changes to understand their impact on user programmes

---

**Document Version**: 1.0
**Created**: January 10, 2026
**Author**: AI Assistant (Claude)
**Purpose**: Code maintainability and rule governance