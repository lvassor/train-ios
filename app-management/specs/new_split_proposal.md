# New Split Templates Proposal

Based on Programme Generation V2.pdf, the following new 3-day split options need templates added to `split_templates.json`.

---

## Current State

| Days | Current JSON Has |
|------|------------------|
| 3-day | Push/Pull/Legs only |

## Proposed Additions (from PDF)

| Days | New Split Options |
|------|-------------------|
| 3-day | Full Body x3 |
| 3-day | 2 Upper / 1 Lower | 
| 3-day | 1 Upper / 2 Lower |

---

## Proposed Templates

### 1. Full Body x3

For beginners or those preferring frequency over specialization.

```json
"30-45 minutes": {
    "Full Body 1": { "Chest": 1, "Back": 1, "Shoulder": 1, "Quad": 1, "Hamstring": 1, "Core": 1 },
    "Full Body 2": { "Chest": 1, "Back": 1, "Shoulder": 1, "Quad": 1, "Hamstring": 1, "Core": 1 },
    "Full Body 3": { "Chest": 1, "Back": 1, "Shoulder": 1, "Quad": 1, "Hamstring": 1, "Core": 1 }
},
"45-60 minutes": {
    "Full Body 1": { "Chest": 1, "Back": 1, "Shoulder": 1, "Quad": 1, "Hamstring": 1, "Glute": 1, "Core": 1 },
    "Full Body 2": { "Chest": 1, "Back": 1, "Shoulder": 1, "Quad": 1, "Hamstring": 1, "Glute": 1, "Core": 1 },
    "Full Body 3": { "Chest": 1, "Back": 1, "Shoulder": 1, "Quad": 1, "Hamstring": 1, "Glute": 1, "Core": 1 }
},
"60-90 minutes": {
    "Full Body 1": { "Chest": 1, "Back": 1, "Shoulder": 1, "Bicep": 1, "Tricep": 1, "Quad": 1, "Hamstring": 1, "Glute": 1, "Core": 1 },
    "Full Body 2": { "Chest": 1, "Back": 1, "Shoulder": 1, "Bicep": 1, "Tricep": 1, "Quad": 1, "Hamstring": 1, "Glute": 1, "Core": 1 },
    "Full Body 3": { "Chest": 1, "Back": 1, "Shoulder": 1, "Bicep": 1, "Tricep": 1, "Quad": 1, "Hamstring": 1, "Glute": 1, "Core": 1 }
}
```

**Rationale:** Matches existing 2-day Full Body structure. Each session hits all major groups; exercise variety comes from canonical deduplication.

| Duration | Exercises/Session | Total/Week |
|----------|-------------------|------------|
| 30-45 min | 6 | 18 |
| 45-60 min | 7 | 21 |
| 60-90 min | 9 | 27 |

---

### 2. Two Upper / One Lower (2U1L)

For users prioritizing upper body development.

```json
"30-45 minutes": {
    "Upper 1": { "Chest": 1, "Back": 1, "Shoulder": 1, "Bicep": 1 },
    "Upper 2": { "Chest": 1, "Back": 1, "Shoulder": 1, "Tricep": 1 },
    "Lower": { "Quad": 2, "Hamstring": 1, "Glute": 1, "Core": 1 }
},
"45-60 minutes": {
    "Upper 1": { "Chest": 2, "Back": 2, "Shoulder": 1, "Bicep": 1 },
    "Upper 2": { "Chest": 2, "Back": 2, "Shoulder": 1, "Tricep": 1 },
    "Lower": { "Quad": 2, "Hamstring": 2, "Glute": 1, "Core": 1 }
},
"60-90 minutes": {
    "Upper 1": { "Chest": 2, "Back": 2, "Shoulder": 2, "Bicep": 1, "Tricep": 1 },
    "Upper 2": { "Chest": 2, "Back": 2, "Shoulder": 2, "Bicep": 1, "Tricep": 1 },
    "Lower": { "Quad": 2, "Hamstring": 2, "Glute": 1, "Core": 1 }
}
```

**Rationale:**
- Upper 1 emphasizes biceps (pulling day accessory)
- Upper 2 emphasizes triceps (pushing day accessory)
- Lower day is denser (2 Quads) since it only occurs once per week

| Duration | Upper 1 | Upper 2 | Lower | Total/Week |
|----------|---------|---------|-------|------------|
| 30-45 min | 4 | 4 | 5 | 13 |
| 45-60 min | 6 | 6 | 6 | 18 |
| 60-90 min | 8 | 8 | 6 | 22 |

---

### 3. One Upper / Two Lower (1U2L)

For users prioritizing lower body/glute development.

```json
"30-45 minutes": {
    "Upper": { "Chest": 1, "Back": 1, "Shoulder": 1, "Bicep": 1, "Tricep": 1 },
    "Lower 1": { "Quad": 1, "Hamstring": 1, "Glute": 1, "Core": 1 },
    "Lower 2": { "Quad": 1, "Hamstring": 1, "Glute": 1, "Core": 1 }
},
"45-60 minutes": {
    "Upper": { "Chest": 2, "Back": 2, "Shoulder": 2, "Bicep": 1, "Tricep": 1 },
    "Lower 1": { "Quad": 2, "Hamstring": 1, "Glute": 1, "Core": 1 },
    "Lower 2": { "Quad": 1, "Hamstring": 2, "Glute": 1, "Core": 1 }
},
"60-90 minutes": {
    "Upper": { "Chest": 2, "Back": 3, "Shoulder": 2, "Bicep": 1, "Tricep": 1 },
    "Lower 1": { "Quad": 2, "Hamstring": 2, "Glute": 1, "Core": 1 },
    "Lower 2": { "Quad": 2, "Hamstring": 2, "Glute": 1, "Core": 1 }
}
```

**Rationale:**
- Upper day is denser since it only occurs once per week
- Lower 1 is quad-focused, Lower 2 is hamstring-focused (at 45-60min) for variety
- Ideal for glute/leg development or athletic performance

| Duration | Upper | Lower 1 | Lower 2 | Total/Week |
|----------|-------|---------|---------|------------|
| 30-45 min | 5 | 4 | 4 | 13 |
| 45-60 min | 8 | 5 | 5 | 18 |
| 60-90 min | 9 | 6 | 6 | 21 |

---

## Comparison: All 3-Day Splits

| Split | Best For | Weekly Volume (45-60 min) |
|-------|----------|---------------------------|
| Push/Pull/Legs | Balanced muscle development | 5 + 5 + 6 = 16 |
| Full Body x3 | Beginners, general fitness | 7 + 7 + 7 = 21 |
| 2 Upper / 1 Lower | Upper body focus | 6 + 6 + 6 = 18 |
| 1 Upper / 2 Lower | Lower body/glute focus | 8 + 5 + 5 = 18 |

---

## Implementation Notes

Files to update:
- `app-management/specs/split_templates.json` - Add new templates
- `trAInSwift/Services/DynamicProgramGenerator.swift` - Add template functions
- Questionnaire UI - Add split selection for 3-day users

The PDF also mentions a new **20-30 minute** duration tier (not currently supported) with "less exercises, focus on major muscle groups."
