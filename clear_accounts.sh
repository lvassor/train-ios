#!/bin/bash
# Clear all user accounts from trAInSwift simulator database
# Run from project root: ./clear_accounts.sh

DEVICE_ID="E7445A9B-882B-4D51-A1ED-2D796A94F40B"
DB_PATH=$(find ~/Library/Developer/CoreSimulator/Devices/$DEVICE_ID/data/Containers/Data/Application -name "TrainSwift.sqlite" 2>/dev/null | head -1)

if [ -z "$DB_PATH" ]; then
    echo "❌ Database not found. Is the app installed on simulator $DEVICE_ID?"
    exit 1
fi

echo "📍 Found database at: $DB_PATH"
echo ""
echo "Current accounts:"
sqlite3 "$DB_PATH" "SELECT ZEMAIL FROM ZUSERPROFILE;"
echo ""

sqlite3 "$DB_PATH" <<EOF
DELETE FROM ZUSERPROFILE;
DELETE FROM ZWORKOUTPROGRAM;
DELETE FROM ZCDWORKOUTSESSION;
DELETE FROM ZQUESTIONNAIRERESPONSE;
EOF

echo "✅ All accounts cleared!"
echo ""
echo "Remaining counts:"
sqlite3 "$DB_PATH" "SELECT 'Users: ' || COUNT(*) FROM ZUSERPROFILE;"
sqlite3 "$DB_PATH" "SELECT 'Programs: ' || COUNT(*) FROM ZWORKOUTPROGRAM;"
sqlite3 "$DB_PATH" "SELECT 'Sessions: ' || COUNT(*) FROM ZCDWORKOUTSESSION;"
