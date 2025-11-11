# Quick Start Guide - SQLite Database Integration

## 🚀 3 Steps to Get Started

### Step 1: Install GRDB (2 minutes)

1. Open `trAInSwift.xcodeproj` in Xcode
2. Go to **File > Add Package Dependencies...**
3. Paste URL: `https://github.com/groue/GRDB.swift`
4. Select **"Up to Next Major Version"** with `6.0.0`
5. Click **"Add Package"**
6. Wait for Xcode to download and add GRDB

### Step 2: Add Database to Project (1 minute)

1. In Xcode's **Project Navigator** (left sidebar), right-click on the `trAInSwift` folder
2. Select **"Add Files to 'trAInSwift'..."**
3. Navigate to `trAInSwift/Resources/exercises.db`
4. **✅ Check** "Copy items if needed"
5. **✅ Check** your app target under "Add to targets"
6. Click **"Add"**

### Step 3: Build & Run (1 minute)

1. Select a simulator (iPhone 15 Pro recommended)
2. Press **⌘B** to build
3. Fix any import errors if needed
4. Press **⌘R** to run
5. Watch console logs - you should see:
   ```
   📦 Database not found in Documents. Copying from bundle...
   ✅ Database copied from bundle to Documents directory
   ✅ Exercise database initialized at: [path]
   📊 Database verification:
      - Exercises: 100
      - Contraindications: 144
      - Experience levels: 3
   ```

## ✅ Verify It's Working

When you complete the questionnaire and generate a program, you should see in the console:

```
🎯 Generating personalized program from questionnaire data...
   Days per week: 3
   Session duration: 45-60 min
   Experience: 6_months_2_years
   Goal: build_muscle
   Max complexity: 3
🏋️ Generating dynamic program from questionnaire data...
✅ Dynamic program generated successfully!
   Program: Push/Pull/Legs Split
   Sessions: 3
   Total exercises: 15
```

If you see **"⚠️ Falling back to hardcoded program"**, check the error message above it for troubleshooting.

## 📋 Quick Testing Checklist

- [ ] GRDB installed (no "No such module 'GRDB'" errors)
- [ ] exercises.db added to project (visible in Project Navigator)
- [ ] App builds successfully (⌘B)
- [ ] App runs without crashes
- [ ] Console shows database initialization logs
- [ ] Program generation shows "Dynamic program generated successfully"
- [ ] Generated program has exercises from database (not generic names)

## 🎯 Test Different Scenarios

Try generating programs with different questionnaire inputs:

### Test Case 1: Beginner with Limited Equipment
```
Experience: "0_6_months"
Goal: "tone_up"
Equipment: ["bodyweight", "dumbbells"]
Days: 3
Injuries: []
```
**Expected**: Complexity ≤ 2, rep range 10-15, bodyweight + dumbbell exercises only

### Test Case 2: Advanced with Knee Injury
```
Experience: "2_plus_years"
Goal: "get_stronger"
Equipment: ["barbells", "dumbbells", "cable_machines"]
Days: 4
Injuries: ["Knee"]
```
**Expected**: Complexity ≤ 4 (with max 1 level-4 as first exercise), rep range 5-8, no knee-contraindicated exercises

### Test Case 3: Intermediate Builder
```
Experience: "6_months_2_years"
Goal: "build_muscle"
Equipment: ["barbells", "dumbbells", "cable_machines", "pin_loaded"]
Days: 5
Injuries: []
```
**Expected**: Complexity ≤ 3, rep range 8-12, all equipment types used

## 🐛 Common Issues

### "No such module 'GRDB'"
**Fix**: Install GRDB via Swift Package Manager (see Step 1)

### "exercises.db not found in app bundle"
**Fix**: Add exercises.db to project (see Step 2). Make sure "Copy items if needed" is checked.

### App builds but crashes on launch
**Fix**: Check console logs for error message. Usually means database file isn't in bundle.

### "Falling back to hardcoded program"
**Fix**: Check console for specific error. Usually means GRDB not installed or database not found.

## 📚 Next Steps

Once it's working:

1. **Update exercises**: See [database-management/README.md](database-management/README.md) for modifying exercise data
2. **Historical docs**: Archived implementation details are in `Documentation/Archive/` if needed

## 🔄 Updating Exercise Data

When you need to modify exercises in the future:

```bash
cd database-management
# Edit CSV files (exercises_new_schema.csv, etc.)
python3 create_database.py
# Database is automatically copied to Resources/
# Rebuild app in Xcode (⌘B)
```

The Python script automatically copies the new database to `trAInSwift/Resources/`.

## 🆘 Still Having Issues?

Check the detailed logs in Xcode console (⌘⇧Y to show console). Most issues are from:
1. GRDB not installed
2. exercises.db not in bundle
3. Database file permissions

## 🎉 Success!

When you see exercises with real names (like "Barbell Back Squat", "Dumbbell Bulgarian Split Squat"), you know it's working!

The program is now personalized based on experience level, equipment, injuries, fitness goal, and training frequency.

---

**Estimated Setup Time**: ~5 minutes | **Difficulty**: Easy | **Prerequisites**: Xcode, macOS
