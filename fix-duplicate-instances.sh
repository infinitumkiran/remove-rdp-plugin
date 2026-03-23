#!/usr/bin/env bash
# Remove duplicate HasField instances from files

set -e

echo "Removing duplicate HasField instances..."

# Find all files with duplicate HasField instances
HS_FILES=$(find common gateway src app -name "*.hs" -type f 2>/dev/null | sort)

for file in $HS_FILES; do
    # Check if file has HasField instances
    if grep -q "Z.HasField" "$file" 2>/dev/null; then
        # Count unique instance declarations
        # If a field appears twice, it's a duplicate

        # Get all instance lines with field names
        instance_lines=$(grep -n "Z.HasField" "$file" 2>/dev/null || true)

        if [ -z "$instance_lines" ]; then
            continue
        fi

        # Extract field names and their line numbers
        # Format: line_number:field_name
        field_lines=$(echo "$instance_lines" | sed -n 's/^\([0-9]*\):.*Z.HasField "\([^"]*\)".*/\1:\2/p')

        # Check for duplicates
        duplicates=$(echo "$field_lines" | cut -d: -f2 | sort | uniq -d)

        if [ -n "$duplicates" ]; then
            echo "Fixing duplicates in: $file"

            # Create temp file
            TEMP_FILE="${file}.tmp.$$"

            # Get the line numbers of the second set of duplicates (the ones to remove)
            # Keep the first occurrence, remove subsequent ones
            lines_to_remove=""
            seen_fields=""

            while IFS=: read -r line field; do
                if echo "$seen_fields" | grep -qw "$field"; then
                    # This is a duplicate, mark for removal
                    # We need to remove the entire instance declaration (single line)
                    lines_to_remove="$lines_to_remove $line"
                else
                    seen_fields="$seen_fields $field"
                fi
            done <<< "$field_lines"

            if [ -n "$lines_to_remove" ]; then
                # Build sed command to remove specific lines
                sed_cmd=""
                for line in $lines_to_remove; do
                    sed_cmd="${sed_cmd}${line}d;"
                done

                sed -e "$sed_cmd" "$file" > "$TEMP_FILE"
                mv "$TEMP_FILE" "$file"
            fi
        fi
    fi
done

echo "Done!"
