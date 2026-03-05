#!/bin/bash
#
# seed_test_accounts.sh
#
# Resets and reseeds test accounts in the iOS Simulator.
# This clears the seeded flag so TestDataSeeder runs again on next launch,
# then builds and runs the app with SEED_TEST_DATA enabled.
#
# Usage:
#   ./scripts/seed_test_accounts.sh                  # Use default device
#   ./scripts/seed_test_accounts.sh "iPhone 17 Pro"  # Specify device name
#
# Test accounts created:
#   test-ppl@train.com / Train123!  — 3-day Push/Pull/Legs
#   test-ul@train.com  / Train123!  — 4-day Upper/Lower x2
#
# Data covers 3 past weeks + current week (up to today).

set -euo pipefail

DEVICE_NAME="${1:-iPhone 17 Pro}"
SCHEME="TrainSwift"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Train Test Account Seeder ==="
echo "Device: $DEVICE_NAME"
echo "Project: $PROJECT_DIR"
echo ""

# 1. Find the simulator device ID
DEVICE_ID=$(xcrun simctl list devices available | grep "$DEVICE_NAME" | head -1 | grep -oE '[0-9A-F-]{36}')

if [ -z "$DEVICE_ID" ]; then
    echo "ERROR: Could not find simulator device '$DEVICE_NAME'"
    echo "Available devices:"
    xcrun simctl list devices available | grep "iPhone\|iPad"
    exit 1
fi

echo "Found device: $DEVICE_ID"

# 2. Boot the simulator if not already booted
BOOT_STATE=$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -o "(Booted)" || true)
if [ -z "$BOOT_STATE" ]; then
    echo "Booting simulator..."
    xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
    sleep 2
fi

# 3. Reset the seed flag so TestDataSeeder will run again
echo "Clearing seed flag..."
xcrun simctl spawn "$DEVICE_ID" defaults delete com.luke.TrainSwift train_test_data_seeded 2>/dev/null || true

# 4. Build with SEED_TEST_DATA flag
echo "Building with SEED_TEST_DATA..."
xcodebuild \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$DEVICE_ID" \
    -derivedDataPath "$PROJECT_DIR/.build" \
    SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) SEED_TEST_DATA' \
    build 2>&1 | tail -3

# 5. Install and launch
APP_PATH=$(find "$PROJECT_DIR/.build" -name "TrainSwift.app" -path "*/Debug-iphonesimulator/*" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "ERROR: Could not find built app"
    exit 1
fi

echo "Installing app..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

echo "Launching app (seeding will run on startup)..."
xcrun simctl launch "$DEVICE_ID" com.luke.TrainSwift

# Give the app time to seed
sleep 5

echo ""
echo "=== Done ==="
echo "Test accounts seeded. Log in with:"
echo "  test-ppl@train.com / Train123!  (3-day PPL)"
echo "  test-ul@train.com  / Train123!  (4-day UL x2)"
echo ""
echo "Data includes sessions up to and including today."
