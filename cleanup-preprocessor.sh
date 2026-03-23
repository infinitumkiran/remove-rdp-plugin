#!/usr/bin/env bash
# Cleanup preprocessor markers from transformed files

set -e

echo "Cleaning up preprocessor markers from transformed files..."

# Find all Haskell files with preprocessor markers
HS_FILES=$(find common gateway src app -name "*.hs" -type f 2>/dev/null | sort)

TOTAL=$(echo "$HS_FILES" | wc -l)
COUNT=0

for file in $HS_FILES; do
    COUNT=$((COUNT + 1))

    # Remove duplicate markers and clean up file
    if grep -q "_recordDotPreprocessorUnused" "$file" 2>/dev/null || \
       grep -q "{-# LINE" "$file" 2>/dev/null || \
       grep -q "import qualified GHC.Records.Extra as Z" "$file" 2>/dev/null; then
        echo "[$COUNT/$TOTAL] Cleaning: $file"

        # Create backup
        cp "$file" "$file.bak"

        # Use sed to cleanup common preprocessor artifacts:
        # 1. Remove _recordDotPreprocessorUnused declarations
        # 2. Remove duplicate imports of GHC.Records.Extra
        # 3. Remove LINE pragmas from preprocessor

        # Process file line by line
        awk '
            # Skip _recordDotPreprocessorUnused lines
            /_recordDotPreprocessorUnused/ { next }

            # Skip LINE pragmas
            /^#\{-# LINE [0-9]+ / { next }

            # Skip duplicate DuplicateRecordFields pragma lines that appear after LINE
            /^#\{-# LANGUAGE DuplicateRecordFields.*HLINT ignore.*Redundant bracket/ { next }

            # Keep everything else
            { print }
        ' "$file.bak" > "$file.tmp"

        # Remove consecutive blank lines (artifact of the transformation)
        awk 'NF || printed { printed=1; print }' "$file.tmp" > "$file"

        # Clean up temporary files
        rm -f "$file.bak" "$file.tmp"
    else
        echo "[$COUNT/$TOTAL] Skipping (no markers): $file"
    fi
done

echo ""
echo "Cleanup complete!"
