# Prompt: Design the Optimal Programme Generation Algorithm

## Context

You are designing the exercise selection algorithm for a fitness app. The app generates personalised workout programmes for users based on their questionnaire answers. Your task is to design the most optimal algorithm for selecting and ordering exercises within each session.

## System Constraints

### User Inputs (from questionnaire)
- Training days per week (1-6)
- Session duration (short, medium, long)
- Experience level (No Experience, Beginner, Intermediate, Advanced)
- Available equipment (user selects from a list)
- Fitness goal (strength, hypertrophy, endurance-focused)
- Target muscle groups (optional priority muscles)
- Injuries (optional)

### Exercise Database Properties
Each exercise has:
- Unique identifier
- Display name (e.g., "Barbell Incline Bench Press")
- Canonical name / movement pattern (e.g., "Bench Press")
- Required equipment
- Complexity level (1-4 scale)
- Compound vs isolation flag
- Primary muscle group
- Programme inclusion flag

### Key Constraints
- **Experience → Complexity**: Less experienced users should only access simpler exercises for safety and progression
- **Deduplication**: Exercises shouldn't repeat within a programme to maintain variety
- **Templates**: Each session has a predefined structure specifying muscle groups and exercise counts

---

## Design Requirements

### Primary Goals
1. **Fill all slots**: If a template specifies 6 exercises, fill all 6 (or as many as possible)
2. **Sensible exercise ordering**: Follow sound training principles - complex exercises first, isolations last
3. **Appropriate for all levels**: All experience levels benefit from both compound and isolation work. 
4. **Variety**: Regenerated programmes should differ
5. **Quality over pure randomness**: Prefer effective exercises without sacrificing slot fill rate

### Secondary Goals
1. Minimise cases where insufficient exercises are found
2. Balance within session (avoid overloading one movement pattern)
3. Respect user preferences (target muscles get more attention)

---

## Your Task

Design the optimal algorithm in TWO sections:

### Section 1: Rules-Based Algorithm
Design a deterministic or semi-deterministic algorithm.
Justify decisions with exercise science principles.

### Section 2: AI-Driven Algorithm


Justify where AI adds value over rules alone.

---

## Deliverable Format

Organise answer clearly into relevant sections for how it would work and what would be needed.