# Programme Slot Filling Fallback Logic (v3 - Final)

## Constraints Classification

**Hard Constraints (never relaxed):**
- Equipment availability
- Attachment availability

**Soft Constraints (relaxed in priority order):**
1. Priority muscle slot count
2. Complexity level restrictions
3. No canonical repeat across programme
4. Muscle group assignment

---

## Baseline Setup

1. **Equipment + Attachments + Experience** → Baseline exercise pool
2. **Days/week + Session duration + Priority muscles** → Split templates with slots per muscle group

**Note on attachments:** If user selects cables but no cable attachments, their baseline pool simply excludes cable exercises (since all cable exercises require attachments). The `attachmentWarning` during questionnaire informs them, but proceeding is their choice. No special handling needed in the fallback cascade.

---

## Fallback Cascade

```
PHASE 0: Initial Assessment
    - Count total slots per muscle group across entire programme
    - Count available candidates per muscle group in baseline pool
    - Identify shortfalls per muscle group (slots_needed - candidates_available)

PHASE 1: Fill with normal constraints
    - Attempt to fill all slots using MCV algorithm
    - Track unfilled slots
    ↓ (if any slots unfilled)

PHASE 2: Decrement priority muscle slots
    - For each muscle group with unfilled slots:
      - IF it's a priority muscle:
        - Reduce total programme slots for that muscle by the shortfall amount
        - Let MCV naturally decide which specific session slots get dropped
    - Retry filling
    ↓ (if still unfilled, OR muscle wasn't a priority)

PHASE 3: Relax complexity rules (per-slot)
    - For each specific slot that STILL can't be filled:
      - No Exp/Beginner: expand from "all, 1" → also allow "2"
      - Intermediate/Advanced: expand from "all, 2" → also allow "1"
    - Retry filling that slot
    ↓ (if still unfilled)

PHASE 4: Relax canonical repeat constraint (per-slot)
    - For each specific slot that STILL can't be filled:
      - Allow exercises with canonical_name already used elsewhere in programme
      - (e.g., "Dumbbell Squat" in Session 1 AND "Barbell Squat" in Session 3)
    - Retry filling that slot
    ↓ (if still unfilled)

PHASE 5: Reassign slot to alternative muscle group
    - For each specific slot that STILL can't be filled:
      - Find muscle group IN THE SAME SESSION with excess capacity
        - excess = candidates_available - slots_needed_in_session
        - Must have excess >= 1 after accounting for this reassignment
      - Reassign the unfilled slot to that muscle group
    - Fill with alternative muscle's exercise
```

---

## Warning Output

Single consolidated warning if ANY soft constraint was relaxed:

> "Based on your equipment and training preferences, we've adjusted a few rules to create the best possible programme for you."

---

## Summary Table

| Phase | Constraint Relaxed | Scope | Trigger |
|-------|-------------------|-------|---------|
| 2 | Priority slot count | Programme-wide (MCV decides session) | Priority muscle can't fill all slots |
| 3 | Complexity level | Per-slot | Slot still unfilled after Phase 2 |
| 4 | Canonical repeat | Per-slot | Slot still unfilled after Phase 3 |
| 5 | Muscle assignment | Per-slot (same session) | Slot still unfilled after Phase 4 |
