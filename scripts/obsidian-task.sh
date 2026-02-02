#!/bin/bash
# obsidian-task.sh - Create a new task

# Load configuration
CONFIG_FILE="$HOME/.config/obsidian-workflow/config"
if [ ! -f "$CONFIG_FILE" ]; then
    osascript -e "display notification \"Config file not found: $CONFIG_FILE\" with title \"Error\" sound name \"Basso\""
    exit 1
fi
source "$CONFIG_FILE"

TASK_DIR="$VAULT/TaskNotes/Tasks"
TASK_NAME="$1"
TOMORROW=$(date -v+1d +%Y-%m-%d)
NOW=$(date +%Y-%m-%dT%H:%M:%S.000+09:00)

# Sanitize filename (remove/replace problematic characters)
FILENAME=$(echo "$TASK_NAME" | sed 's/[\/:\\|]/-/g')

TASK_PATH="$TASK_DIR/$FILENAME.md"

cat > "$TASK_PATH" << EOF
---
status: open
priority: normal
scheduled: $TOMORROW
projects: []
dateCreated: $NOW
dateModified: $NOW
tags:
  - task
---

EOF

# macOS notification
osascript -e "display notification \"$TASK_NAME (scheduled: $TOMORROW)\" with title \"Task Created\" sound name \"Pop\""
