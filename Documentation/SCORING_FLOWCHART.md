# Exercise Selection Scoring Flowchart

## Overview

This document visualizes the exercise selection algorithm used in the trAIn iOS app's program generator.

## Main Selection Flow

```mermaid
flowchart TD
    Start([Start Exercise Selection]) --> BuildPool[Stage 1: Build User Pool]

    BuildPool --> FilterEquip[Filter by User Equipment]
    FilterEquip --> FilterComplex[Filter by Max Complexity from DB]
    FilterComplex --> CheckEmpty{Pool Empty?}

    CheckEmpty -->|Yes| AddWarning2[Add Warning: noExercisesForMuscle]
    AddWarning2 --> ReturnEmpty[Return Empty List]

    CheckEmpty -->|No| ScoreExercises[Stage 2: Score All Exercises]

    ScoreExercises --> CheckC4{Allow Complexity 4<br>& Must Be First?}

    CheckC4 -->|Yes| SelectC4[Select Complexity-4 First]
    SelectC4 --> WeightedC4[Weighted Random from C4 Pool]
    WeightedC4 --> MarkC4[Mark C4 Selected]
    MarkC4 --> SelectRemaining

    CheckC4 -->|No| SelectRemaining[Select Remaining Exercises]

    SelectRemaining --> LoopStart{More Slots<br>to Fill?}

    LoopStart -->|Yes| CheckHasC4{Already Has<br>Complexity 4?}
    CheckHasC4 -->|Yes| CapComplexity[Cap at Complexity 3]
    CheckHasC4 -->|No| UseAllComplexity[Use All Complexities]

    CapComplexity --> PreferVariety
    UseAllComplexity --> PreferVariety[Prefer Different Canonical Names]

    PreferVariety --> WeightedSelect[Weighted Random Selection]
    WeightedSelect --> AddToList[Add to Selected List]
    AddToList --> RemoveFromPool[Remove from Pool]
    RemoveFromPool --> LoopStart

    LoopStart -->|No| SortDisplay[Stage 3: Sort for Display]

    SortDisplay --> SortCompounds[Compounds First]
    SortCompounds --> SortByComplexity[Then by Complexity DESC]
    SortByComplexity --> CheckCount{Found Enough<br>Exercises?}

    CheckCount -->|No| AddWarning3[Add Warning: insufficientExercises]
    AddWarning3 --> ReturnResult
    CheckCount -->|Yes| ReturnResult[Return Exercises + Warnings]

    ReturnEmpty --> End([End])
    ReturnResult --> End
```

## Scoring Algorithm

```mermaid
flowchart TD
    ScoreStart([Score Exercise]) --> CheckIsolation{Is Isolation?}

    CheckIsolation -->|Yes| CheckExpLevel[Check Experience Level]
    CheckExpLevel --> Advanced{Advanced?}
    Advanced -->|Yes| Score8[Score = 8 pts]
    Advanced -->|No| Intermediate{Intermediate?}
    Intermediate -->|Yes| Score6[Score = 6 pts]
    Intermediate -->|No| Score4[Score = 4 pts]

    CheckIsolation -->|No| CheckComplexity[Check Complexity Level]
    CheckComplexity --> C4{Complexity 4?}
    C4 -->|Yes| Score20[Score = 20 pts]
    C4 -->|No| C3{Complexity 3?}
    C3 -->|Yes| Score15[Score = 15 pts]
    C3 -->|No| C2{Complexity 2?}
    C2 -->|Yes| Score10[Score = 10 pts]
    C2 -->|No| Score5[Score = 5 pts]

    Score8 --> ReturnScore([Return Score])
    Score6 --> ReturnScore
    Score4 --> ReturnScore
    Score20 --> ReturnScore
    Score15 --> ReturnScore
    Score10 --> ReturnScore
    Score5 --> ReturnScore
```

## Weighted Random Selection

```mermaid
flowchart TD
    WRStart([Weighted Random Select]) --> CalcTotal[Calculate Total Score]
    CalcTotal --> GenRandom[Generate Random 0 to Total-1]
    GenRandom --> InitCumulative[cumulative = 0]

    InitCumulative --> LoopExercise[For Each Exercise]
    LoopExercise --> AddScore[cumulative += exercise.score]
    AddScore --> CheckRandom{random < cumulative?}

    CheckRandom -->|Yes| SelectThis[Select This Exercise]
    SelectThis --> ReturnEx([Return Exercise])

    CheckRandom -->|No| NextEx{More Exercises?}
    NextEx -->|Yes| LoopExercise
    NextEx -->|No| SelectLast[Select Last Exercise]
    SelectLast --> ReturnEx
```

## User Pool Construction

```mermaid
flowchart LR
    subgraph Database
        AllExercises[(All Exercises)]
        ExpComplexity[(Experience Complexity)]
    end

    subgraph Filters
        F1[Equipment Filter]
        F2[Complexity Filter]
        F3[Programme Filter]
    end

    subgraph UserInput
        Equipment[User Equipment]
        Experience[Experience Level]
    end

    Equipment --> F1
    AllExercises --> F1
    F1 --> F2

    Experience --> ExpComplexity
    ExpComplexity --> MaxComplexity[Max Complexity]
    MaxComplexity --> F2
    F2 --> F3

    F3 --> UserPool[User Pool]

    subgraph UIOnly[UI Display Only]
        Injuries[User Injuries]
        WarningIcon[Warning Icon in Workout Overview]
    end

    Injuries --> WarningIcon
```

**Note**: Injuries do NOT filter exercises. They are only used to display warning icons in the Workout Overview UI for exercises that may affect injured areas.

## Warning Flow

```mermaid
flowchart TD
    GenStart([Program Generation]) --> CollectWarnings[Collect Warnings During Generation]

    CollectWarnings --> W1{Empty Pool?}
    W1 -->|Yes| AddNoEx[Add: noExercisesForMuscle]

    CollectWarnings --> W3{Found < Requested?}
    W3 -->|Yes| AddInsuff[Add: insufficientExercises]

    AddNoEx --> Dedupe
    AddInsuff --> Dedupe
    W1 -->|No| CheckNext1[Continue]
    W3 -->|No| CheckNext3[Continue]

    CheckNext1 --> Dedupe[De-duplicate Warnings]
    CheckNext3 --> Dedupe

    Dedupe --> HasWarnings{Any Warnings?}
    HasWarnings -->|Yes| StoreWarnings[Store in ViewModel]
    StoreWarnings --> SaveProgram[Save Program]
    SaveProgram --> ShowAlert[Show iOS Alert]

    HasWarnings -->|No| SaveProgram2[Save Program]
    SaveProgram2 --> Complete([Complete])
    ShowAlert --> Complete
```

**Note**: Injuries are handled separately in the Workout Overview UI, not during program generation.

## Scoring Table Reference

| Type | Condition | Score |
|------|-----------|-------|
| Compound | Complexity 4 | 20 |
| Compound | Complexity 3 | 15 |
| Compound | Complexity 2 | 10 |
| Compound | Complexity 1 | 5 |
| Isolation | Advanced | 8 |
| Isolation | Intermediate | 6 |
| Isolation | Beginner/NoExp | 4 |

## Key Files

| File | Responsibility |
|------|----------------|
| `ExerciseRepository.swift` | buildUserPool(), scoreAndSelectExercises(), sortForDisplay() |
| `DynamicProgramGenerator.swift` | generateProgramWithWarnings(), generateSessionsWithWarnings() |
| `WorkoutViewModel.swift` | Warning alert state, showWarnings() |
| `QuestionnaireView.swift` | Alert presentation via .alert() modifier |

---

**Created**: December 9, 2025
**Version**: 1.0
