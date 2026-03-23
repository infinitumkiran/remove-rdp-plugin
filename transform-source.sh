#!/usr/bin/env bash
# Transform Haskell source files using record-dot-preprocessor
# This replaces record dot syntax with getField/setField calls

set -e

# Get the path to record-dot-preprocessor executable
# Use the one from nix store or build it
PREPROCESSOR=""

if [ -n "$1" ]; then
    PREPROCESSOR="$1"
else
    echo "Usage: $0 <path-to-record-dot-preprocessor-executable>"
    echo "Example: $0 result/bin/record-dot-preprocessor"
    echo ""
    echo "To get the executable:"
    echo "  nix build .#record-dot-preprocessor --impure"
    exit 1
fi

if [ ! -x "$PREPROCESSOR" ]; then
    echo "Error: Cannot find executable at $PREPROCESSOR"
    exit 1
fi

echo "Using preprocessor: $PREPROCESSOR"

# Find all Haskell source files in the project (excluding forks)
HS_FILES=$(find common gateway src app -name "*.hs" -type f 2>/dev/null | grep -v "^forks/" | sort)

TOTAL=$(echo "$HS_FILES" | wc -l)
COUNT=0

for file in $HS_FILES; do
    COUNT=$((COUNT + 1))

    # Check if file contains record dot syntax (quick check)
    if grep -q '\.[a-zA-Z_]' "$file" 2>/dev/null || \
       grep -q '{[a-zA-Z_]' "$file" 2>/dev/null; then
        echo "[$COUNT/$TOTAL] Transforming: $file"

        # Create backup
        cp "$file" "$file.bak"

        # Run preprocessor: original input output
        # Format: record-dot-preprocessor original input output
        if $PREPROCESSOR "$file" "$file" "$file.tmp"; then
            mv "$file.tmp" "$file"
            rm "$file.bak"
        else
            echo "  Error transforming $file, restoring backup"
            mv "$file.bak" "$file"
            rm -f "$file.tmp"
        fi
    else
        echo "[$COUNT/$TOTAL] Skipping (no record dot syntax): $file"
    fi
done

echo ""
echo "Transformation complete!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Remove plugin from cabal files:"
echo "   - Remove: -fplugin=RecordDotPreprocessor"
echo "   - Remove: -fplugin-opt=RecordDotPreprocessor:--replace-source"
echo "   - Keep: record-hasfield dependency (for getField/setField)"
echo "3. Build the project to verify it compiles without the plugin"
