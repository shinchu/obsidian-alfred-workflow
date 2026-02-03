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
TODAY=$(date +%Y-%m-%d)
NOW=$(date +%Y-%m-%dT%H:%M:%S.000+09:00)

# Use Alfred variables (passed as environment variables)
TASK_NAME="$task_name"
PROJECT_NAME="$project_name"

if [ -z "$TASK_NAME" ]; then
    osascript -e "display notification \"Task name is empty\" with title \"Error\" sound name \"Basso\""
    exit 1
fi

if [ -n "$PROJECT_NAME" ]; then
    TARGET_DIR="$TASK_DIR/$PROJECT_NAME"
    mkdir -p "$TARGET_DIR"
else
    TARGET_DIR="$TASK_DIR"
fi

# Sanitize filename (remove/replace problematic characters)
FILENAME=$(echo "$TASK_NAME" | sed 's/[\/:\\|]/-/g')

TASK_PATH="$TARGET_DIR/$FILENAME.md"

# Build projects array for frontmatter
if [ -n "$PROJECT_NAME" ]; then
    PROJECTS_LINE="projects:\n  - \"[[$PROJECT_NAME]]\""
else
    PROJECTS_LINE="projects: []"
fi

cat > "$TASK_PATH" << EOF
---
status: open
priority: normal
scheduled: $TODAY
$(echo -e "$PROJECTS_LINE")
dateCreated: $NOW
dateModified: $NOW
tags:
  - task
---

EOF

# macOS notification
if [ -n "$PROJECT_NAME" ]; then
    osascript -e "display notification \"$TASK_NAME in $PROJECT_NAME\" with title \"Task Created\" sound name \"Pop\""
else
    osascript -e "display notification \"$TASK_NAME (scheduled: $TODAY)\" with title \"Task Created\" sound name \"Pop\""
fi
