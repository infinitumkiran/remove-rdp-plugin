#!/usr/bin/env bash
# Cleanup preprocessor markers from transformed files - version 2

set -e

echo "Cleaning up preprocessor markers from transformed files..."

# Find all Haskell files with preprocessor markers
HS_FILES=$(find common gateway src app -name "*.hs" -type f 2>/dev/null | sort)

TOTAL=$(echo "$HS_FILES" | wc -l)
COUNT=0

for file in $HS_FILES; do
    COUNT=$((COUNT + 1))

    # Check if file needs cleaning
    if grep -q "_recordDotPreprocessorUnused\|{-# LINE\|GHC.Records.Extra as Z" "$file" 2>/dev/null; then
        echo "[$COUNT/$TOTAL] Cleaning: $file"

        # Create a temp file
        TEMP_FILE="${file}.tmp.$$"

        # Read file and process
        # We need to:
        # 1. Remove _recordDotPreprocessorUnused declarations
        # 2. Remove LINE pragmas
        # 3. Remove duplicate DuplicateRecordFields pragmas
        # 4. Remove duplicate GHC.Records.Extra imports

        # Use a more comprehensive approach with sed
        sed -e '/^_recordDotPreprocessorUnused.*$/d' \
            -e '/{-# LINE [0-9]*/d' \
            -e '/import qualified GHC\.Records\.Extra as Z/d' \
            -e '/{-# LANGUAGE DuplicateRecordFields, DataKinds, FlexibleInstances, TypeApplications, FlexibleContexts, MultiParamTypeClasses, TypeFamilies, TypeOperators, GADTs, UndecidableInstances #-}/d' \
            -e '/{- HLINT ignore "Redundant bracket" -}/d' \
            "$file" > "$TEMP_FILE"

        # Replace original file
        mv "$TEMP_FILE" "$file"

        # Remove consecutive blank lines (but keep single blank lines)
        awk 'NF || printed { printed=1; print } END { if (NF) print "" }' "$file" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$file"
    else
        echo "[$COUNT/$TOTAL] Skipping (no markers): $file"
    fi
done

echo ""
echo "Cleanup complete!"
