#!/bin/bash
# obsidian-end.sh - End tracking work

# Load configuration
CONFIG_FILE="$HOME/.config/obsidian-workflow/config"
if [ ! -f "$CONFIG_FILE" ]; then
    osascript -e "display notification \"Config file not found: $CONFIG_FILE\" with title \"Error\" sound name \"Basso\""
    exit 1
fi
source "$CONFIG_FILE"

TODAY=$(date +%Y-%m-%d)
DAILY_PATH="$VAULT/Daily/$TODAY.md"
TRACKER_FILE="$HOME/.obsidian-work-tracker"
END_TIME=$(date +%H:%M)

# Check if tracker file exists
if [ ! -f "$TRACKER_FILE" ]; then
    osascript -e "display notification \"No work in progress\" with title \"Error\" sound name \"Basso\""
    exit 1
fi

# Read tracker file
TRACKER_DATA=$(cat "$TRACKER_FILE")
START_TIME=$(echo "$TRACKER_DATA" | cut -d'|' -f1)
WORK=$(echo "$TRACKER_DATA" | cut -d'|' -f2-)

# Calculate duration
START_MINUTES=$((10#${START_TIME:0:2} * 60 + 10#${START_TIME:3:2}))
END_MINUTES=$((10#${END_TIME:0:2} * 60 + 10#${END_TIME:3:2}))
DURATION_MINUTES=$((END_MINUTES - START_MINUTES))

if [ $DURATION_MINUTES -lt 0 ]; then
    DURATION_MINUTES=$((DURATION_MINUTES + 1440))  # Handle day wrap
fi

HOURS=$((DURATION_MINUTES / 60))
MINS=$((DURATION_MINUTES % 60))

if [ $HOURS -gt 0 ]; then
    DURATION="${HOURS}h${MINS}m"
else
    DURATION="${MINS}m"
fi

# Add end entry to Daily note
echo "- $END_TIME 🔴 終了: $WORK ($DURATION)" >> "$DAILY_PATH"

# Remove tracker file
rm "$TRACKER_FILE"

# macOS notification
osascript -e "display notification \"$WORK ($DURATION)\" with title \"Work Ended\" sound name \"Pop\""
