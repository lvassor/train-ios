# Monte Carlo Simulation Report
## Programme Generation Edge Case Analysis

**Date**: December 9, 2025
**Simulation Runs**: 1,000
**Random Seed**: 42

---

## Executive Summary

The simulation tested 1,000 random user profiles against the programme generation algorithm to identify failure patterns. The overall **success rate was 44.3%**, with 55.7% of simulations failing to generate a complete programme.

| Metric | Value |
|--------|-------|
| Total Simulations | 1,000 |
| Successful | 443 (44.3%) |
| ERR_ZERO_EXERCISES | 511 (51.1%) |
| ERR_LOW_VARIETY | 46 (4.6%) |

---

## Critical Finding #1: NO_EXPERIENCE = 100% Failure Rate

**Root Cause**: The database sets `max_complexity = 1` for NO_EXPERIENCE users, but several muscle groups have **zero exercises at complexity level 1**.

### Exercises Available at Complexity = 1

| Muscle | Count | Equipment Required |
|--------|-------|-------------------|
| **Back** | **0** | N/A - impossible to fill |
| **Biceps** | **0** | N/A - impossible to fill |
| Triceps | 1 | Cables only |
| Chest | 3 | Other only (bodyweight) |
| Shoulders | 4 | Dumbbells, Cables, Barbells |
| Quads | 5 | Pin-Loaded, Plate-Loaded, Dumbbells, Kettlebells, Cables |
| Hamstrings | 6 | Other, Barbells, Pin-Loaded, Plate-Loaded |
| Glutes | 4 | Dumbbells, Other, Kettlebells |
| Core | 5 | Other, Cables |

**Impact**: Any programme requiring Back or Biceps exercises will fail 100% for NO_EXPERIENCE users.

### NO_EXPERIENCE Failure Breakdown

| Muscle | Failures |
|--------|----------|
| Back | 139 |
| Chest | 108 |
| Triceps | 101 |
| Shoulders | 63 |
| Biceps | 61 |

---

## Critical Finding #2: Single Equipment Selection = 93% Failure Rate

Users selecting only one equipment type experience near-total failure rates:

| Equipment Type | Failure Rate | Coverage Gap |
|----------------|--------------|--------------|
| Barbells | 100% | No Back/Chest at low complexity |
| Plate-Loaded Machines | 100% | Only Quads/Hamstrings |
| Kettlebells | 100% | Very limited muscle coverage |
| Pin-Loaded Machines | 100% | Only Quads/Hamstrings/Back |
| Other (Bodyweight) | 100% | Limited to Chest/Core/Hamstrings |
| Dumbbells | 82% | Best coverage but still gaps |
| Cables | 79% | Good variety but missing some muscles |

### Equipment Count vs Failure Rate

| Equipment Types Selected | Failure Rate |
|-------------------------|--------------|
| 1 | 92.9% |
| 2 | 78.5% |
| 3 | 70.1% |
| 4 | 53.6% |
| 5 | 38.1% |
| 6 | 30.2% |
| 7 (all) | 25.5% |

---

## Critical Finding #3: Higher Days/Week = Higher Failure Rate

More training days require more unique exercises, exhausting available pools:

| Days/Week | Failure Rate | Programme Type |
|-----------|--------------|----------------|
| 1 | 35.0% | Full Body |
| 2 | 50.5% | Upper/Lower or 2x Full Body |
| 3 | 54.0% | Push/Pull/Legs |
| 4 | 51.0% | Upper/Lower x2 |
| 5 | 62.8% | PPL + Upper/Lower |
| 6 | 81.6% | PPL + PPL B (requires 6-8 unique per muscle) |

---

## Experience Level x Equipment Count Matrix

Failure rates by experience level and number of equipment types selected:

| Experience | 1 equip | 2 equip | 3 equip | 4 equip | 5 equip | 6 equip | 7 equip |
|------------|---------|---------|---------|---------|---------|---------|---------|
| NO_EXPERIENCE | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| BEGINNER | 89% | 78% | 56% | 46% | 24% | 6% | 2% |
| INTERMEDIATE | 91% | 69% | 56% | 44% | 14% | 7% | 8% |
| ADVANCED | 87% | 60% | 68% | 34% | 7% | 10% | 11% |

---

## Most Commonly Failing Muscles

| Muscle | Total Failures | Primary Cause |
|--------|----------------|---------------|
| Biceps | 207 | No complexity-1 exercises |
| Triceps | 199 | Only 1 complexity-1 exercise (Cables) |
| Back | 189 | No complexity-1 exercises |
| Chest | 178 | Only bodyweight at complexity-1 |
| Shoulders | 150 | Limited equipment options |
| Core | 74 | Only Other/Cables at complexity-1 |
| Glutes | 35 | Limited options |
| Hamstrings | 25 | Good coverage |
| Quads | 23 | Good coverage |

---

## Database State Analysis

### Current Experience Complexity Rules

| Experience Level | Max Complexity | Max C4/Session | C4 Must Be First |
|-----------------|----------------|----------------|------------------|
| NO_EXPERIENCE | 1 | 0 | No |
| BEGINNER | 2 | 0 | No |
| INTERMEDIATE | 3 | 0 | No |
| ADVANCED | 4 | 1 | Yes |

### Exercise Distribution by Complexity

| Muscle | C<=1 | C<=2 | C<=3 | C<=4 |
|--------|------|------|------|------|
| Back | 0 | 8 | 12 | 14 |
| Chest | 3 | 10 | 15 | 15 |
| Triceps | 1 | 4 | 8 | 9 |
| Biceps | 0 | 5 | 5 | 5 |
| Shoulders | 4 | 8 | 12 | 12 |

---

## Recommendations

### Option A: Increase NO_EXPERIENCE Max Complexity

Change `max_complexity` from 1 to 2 for NO_EXPERIENCE users. This would:
- Give access to 8 Back exercises (currently 0)
- Give access to 5 Biceps exercises (currently 0)
- Reduce NO_EXPERIENCE failure rate significantly

### Option B: Add Complexity-1 Exercises

Add beginner-friendly exercises at complexity level 1:
- **Back**: Assisted rows, band exercises
- **Biceps**: Assisted curls, band curls

### Option C: Questionnaire Validation

Add validation during questionnaire:
- Warn users selecting <3 equipment types about limited variety
- Cap days/week recommendations based on equipment count
- Show equipment coverage preview before programme generation

### Option D: Graceful Degradation

When a muscle group has insufficient exercises:
- Substitute with secondary muscle exercises
- Reduce session volume rather than failing
- Offer alternative equipment suggestions

---

## Appendix: Simulation Configuration

```
Equipment Options: Barbells, Dumbbells, Kettlebells, Cables,
                   Pin-Loaded Machines, Plate-Loaded Machines, Other

Experience Levels: NO_EXPERIENCE, BEGINNER, INTERMEDIATE, ADVANCED

Days Options: 1, 2, 3, 4, 5, 6

Duration Options: 30-45 min, 45-60 min, 60-90 min

Goals: Muscle Growth, Strength, General Fitness

Focus Muscle: 30% chance of random selection
Excluded Muscles: 20% chance of 1-2 exclusions
```

---

**Report Generated By**: Monte Carlo Simulation Framework
**Database**: exercises.db (138 exercises)
**Algorithm Version**: Weighted Random Selection v1.0
