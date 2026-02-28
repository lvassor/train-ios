# UX/UI Improvement Log

Each line documents a single UX/UI change made during the overhaul.

## Phase 1: Design System Foundation
- Added `trainTextOnPrimary` color token (#1a1a2e) for dark text on orange backgrounds — WCAG AA compliant
- Added `trainMuscleDefault` (#3f3f3f) and `trainMuscleInactive` (#8a8a8a) tokens for muscle diagram colors
- Added `trainConfetti` color array for celebration confetti — 5 decorative colors centralised
- Added `trainInputBorder` and `trainInputBorderSubtle` adaptive tokens for input field borders
- Added `ShadowStyle` token system with 9 elevation levels (none/borderLine/subtle/card/elevated/modal/media/iconOverlay/dragging/navBar)
- Added `BorderWidth` tokens (hairline/standard/emphasis/heavy)
- Added `OpacityLevel` tokens (disabled/secondary/primary/full)
- Added `AnimationDuration` tokens (quick/standard/slow/celebration)
- Replaced 16 hardcoded `Color(hex:)` calls across 7 files with semantic tokens
- Replaced 10 raw `Color.green` / `.foregroundColor(.green)` with `.trainSuccess` across 5 files
- Replaced 10 raw `Color.orange` / `.foregroundColor(.orange)` with `.trainWarning` across 4 files
- Replaced 11 raw `Color.red` / `.foregroundColor(.red)` with `.trainError` across 9 files (kept Apple Health heart icon red)
- Replaced 15 ad-hoc `.shadow()` calls with `.shadowStyle()` tokens across 9 files
- Fixed 4 hardcoded `cornerRadius` values to use `CornerRadius` tokens across 3 files
- Eliminated 17 `@Environment(\.colorScheme)` manual branching declarations across 4 files
- Replaced 11 conditional color expressions with adaptive Asset Catalog tokens
