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

    # Create temp file
    tmpfile=$(mktemp)

    # Run preprocessor (original input output format)
    if "$PREPROCESSOR" "$file" "$file" "$tmpfile" 2>/dev/null; then
        # Check if output is different
        if ! diff -q "$file" "$tmpfile" >/dev/null 2>&1; then
            # Add import for GHC.Records.Extra if needed
            if grepq "Z\.getField\|Z\.setField\|Z\.HasField" "$tmpfile" 2>/dev/null; then
                if ! grep -q "import qualified GHC.Records.Extra as Z" "$tmpfile"; then
                    # Add import after module declaration
                    awk '
                        /^module / { found=1 }
                        found && /^where/ { print; print "import qualified GHC.Records.Extra as Z"; found=0; next }
                        { print }
                    ' "$tmpfile" > "${tmpfile}.new"
                    mv "${tmpfile}.new" "$tmpfile"
                fi
            fi
            mv "$tmpfile" "$file"
            echo "  -> Transformed"
        fi
    fi

    rm -f "$tmpfile" "${tmpfile}.new"
done

echo "Done! Processed $TOTAL files."
