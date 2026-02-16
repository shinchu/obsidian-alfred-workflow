#!/bin/bash
# obsidian-done.sh - Mark a task as done

# Load configuration
CONFIG_FILE="$HOME/.config/obsidian-workflow/config"
if [ ! -f "$CONFIG_FILE" ]; then
    osascript -e "display notification \"Config file not found: $CONFIG_FILE\" with title \"Error\" sound name \"Basso\""
    exit 1
fi
source "$CONFIG_FILE"

TASK_PATH="$1"
NOW=$(date +%Y-%m-%dT%H:%M:%S.000+09:00)

if [ ! -f "$TASK_PATH" ]; then
    osascript -e "display notification \"Task file not found\" with title \"Error\" sound name \"Basso\""
    exit 1
fi

TASK_NAME=$(basename "$TASK_PATH" .md)

# Update frontmatter: status → done, add completedDate, update dateModified
TEMP_FILE=$(mktemp)
IN_FRONTMATTER=false
FRONTMATTER_COUNT=0
COMPLETED_DATE_ADDED=false

while IFS= read -r line || [ -n "$line" ]; do
    if [ "$line" = "---" ]; then
        FRONTMATTER_COUNT=$((FRONTMATTER_COUNT + 1))
        if [ "$FRONTMATTER_COUNT" -eq 2 ] && [ "$COMPLETED_DATE_ADDED" = false ]; then
            # Add completedDate before closing ---
            echo "completedDate: $NOW" >> "$TEMP_FILE"
            COMPLETED_DATE_ADDED=true
        fi
        echo "$line" >> "$TEMP_FILE"
        continue
    fi

    if [ "$FRONTMATTER_COUNT" -eq 1 ]; then
        # Inside frontmatter
        if [[ "$line" == status:* ]]; then
            echo "status: done" >> "$TEMP_FILE"
        elif [[ "$line" == dateModified:* ]]; then
            echo "dateModified: $NOW" >> "$TEMP_FILE"
        elif [[ "$line" == completedDate:* ]]; then
            echo "completedDate: $NOW" >> "$TEMP_FILE"
            COMPLETED_DATE_ADDED=true
        else
            echo "$line" >> "$TEMP_FILE"
        fi
    else
        echo "$line" >> "$TEMP_FILE"
    fi
done < "$TASK_PATH"

mv "$TEMP_FILE" "$TASK_PATH"

# macOS notification
osascript -e "display notification \"$TASK_NAME\" with title \"Task Completed ✅\" sound name \"Pop\""
