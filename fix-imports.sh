#!/usr/bin/env bash
# Add missing GHC.Records.Extra imports to files that use Z. references

set -e

echo "Adding missing GHC.Records.Extra imports..."

# Find all files that use Z. references but don't have the import
HS_FILES=$(find common gateway src app -name "*.hs" -type f 2>/dev/null | sort)

TOTAL=$(echo "$HS_FILES" | wc -l)
COUNT=0

for file in $HS_FILES; do
    COUNT=$((COUNT + 1))

    # Check if file uses Z. references
    if grep -q "Z\." "$file" 2>/dev/null; then
        # Check if file already has the import
        if ! grep -q "import qualified GHC.Records.Extra as Z" "$file" 2>/dev/null; then
            echo "[$COUNT/$TOTAL] Adding import to: $file"

            # Find the module line and add import after it
            TEMP_FILE="${file}.tmp.$$"

            # Add import after module line
            awk '
                /^module / { in_module = 1 }
                in_module && /^where/ {
                    print
                    print ""
                    print "import qualified GHC.Records.Extra as Z"
                    in_module = 0
                    next
                }
                { print }
            ' "$file" > "$TEMP_FILE"

            mv "$TEMP_FILE" "$file"
        else
            echo "[$COUNT/$TOTAL] Already has import: $file"
        fi
    else
        echo "[$COUNT/$TOTAL] No Z. refs: $file"
    fi
done

echo ""
echo "Import fix complete!"
