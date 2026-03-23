#!/bin/bash
set -e

PREPROCESSOR="/home/kiransai-abhishek/repos/euler-api-gateway/forks/record-dot-preprocessor/result/bin/record-dot-preprocessor"

# Count total files
TOTAL=$(find common/src gateway/src -name "*.hs" -type f 2>/dev/null | wc -l)
echo "Processing $TOTAL Haskell files..."

# Process each file
COUNT=0
find common/src gateway/src -name "*.hs" -type f 2>/dev/null | while read -r file; do
    COUNT=$((COUNT + 1))
    if [ $((COUNT % 100)) -eq 0 ]; then
        echo "[$COUNT/$TOTAL] Processing: $file"
    fi

    # Run preprocessor with --replace-source flag
    "$PREPROCESSOR" "$file" "$file" --replace-source 2>/dev/null || true
done

echo "Done! Processed $TOTAL files."
