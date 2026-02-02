#!/bin/bash
# obsidian-start.sh - Start tracking work

VAULT="$HOME/Dropbox/Sync/Obsidian"
TODAY=$(date +%Y-%m-%d)
DAILY_PATH="$VAULT/Daily/$TODAY.md"
TEMPLATE_PATH="$VAULT/Templates/Daily.md"
TIME=$(date +%H:%M)
WORK="$1"
TRACKER_FILE="$HOME/.obsidian-work-tracker"

# Create Daily note if not exists
if [ ! -f "$DAILY_PATH" ]; then
    cp "$TEMPLATE_PATH" "$DAILY_PATH"
fi

# Save current work to tracker file
echo "$TIME|$WORK" > "$TRACKER_FILE"

# Add start entry to Daily note
echo "- $TIME 🟢 開始: $WORK" >> "$DAILY_PATH"

# macOS notification
osascript -e "display notification \"$WORK\" with title \"Work Started\" sound name \"Pop\""
