#!/bin/bash
# obsidian-start.sh - Start tracking work

# Load configuration
CONFIG_FILE="$HOME/.config/obsidian-workflow/config"
if [ ! -f "$CONFIG_FILE" ]; then
    osascript -e "display notification \"Config file not found: $CONFIG_FILE\" with title \"Error\" sound name \"Basso\""
    exit 1
fi
source "$CONFIG_FILE"

TODAY=$(date +%Y-%m-%d)
DAILY_PATH="$VAULT/Daily/$TODAY.md"
TEMPLATE_PATH="$VAULT/Templates/Daily.md"
TIME=$(date +%H:%M)
WORK="$1"
TASK_PATH="$task_path"  # Alfred variable: task file path (empty for free text)
TRACKER_FILE="$HOME/.obsidian-work-tracker"

# Create Daily note if not exists
if [ ! -f "$DAILY_PATH" ]; then
    cp "$TEMPLATE_PATH" "$DAILY_PATH"
fi

# Save current work to tracker file (TIME|WORK|TASK_PATH)
echo "$TIME|$WORK|$TASK_PATH" > "$TRACKER_FILE"

# Add start entry to Daily note
echo "- $TIME 🟢 開始: $WORK" >> "$DAILY_PATH"

# macOS notification
osascript -e "display notification \"$WORK\" with title \"Work Started\" sound name \"Pop\""
