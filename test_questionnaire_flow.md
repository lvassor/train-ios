# Questionnaire Flow Test Plan

## PR #1: Core Flow Restructuring Changes

### Before (15 screens):
1. Welcome → Section 1 Cover → 8 Questions → Section 2 Cover → 5 Questions

### After (14 screens):
1. Welcome → 13 Questions directly (no cover pages)

### New Question Order:
1. Goals
2. Name
3. Age
4. Gender
5. Height
6. Weight
7. Experience
8. Training Days
9. Split Selection
10. Session Duration
11. Equipment
12. Muscle Groups
13. Injuries

### Changes Made:
- ✅ Removed section cover pages (sections 0 and 2)
- ✅ Reordered questions to put personal info early (steps 2-6)
- ✅ Updated progress tracking to show single progress bar
- ✅ Simplified navigation logic (single currentStep instead of currentSection + currentStepInSection)
- ✅ Updated validation logic for new step order
- ✅ Updated equipment warning to use new step number (10)

### Test Cases:
1. **Flow Continuity**: All 13 steps should transition smoothly
2. **Progress Bar**: Should show 1/13, 2/13, ..., 13/13
3. **Back Navigation**: Should work correctly from any step
4. **Validation**: Each step should validate properly before allowing continue
5. **Equipment Warning**: Should trigger on step 10 if only one equipment type selected
6. **Final Step**: Should show "Generate Your Program" button on step 13