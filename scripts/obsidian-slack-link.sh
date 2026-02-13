#!/bin/bash
# obsidian-slack-link.sh - Attach a Slack message link to a task file

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
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")

# Get Slack URL from clipboard
SLACK_URL=$(pbpaste 2>/dev/null)
SLACK_URL_PATTERN='^https://[a-zA-Z0-9_-]+\.slack\.com/archives/'

if ! [[ "$SLACK_URL" =~ $SLACK_URL_PATTERN ]]; then
    osascript -e "display notification \"Clipboard does not contain a Slack URL\" with title \"Error\" sound name \"Basso\""
    exit 1
fi

# Determine mode: create (new task) or attach (existing task)
if [ -n "$task_name" ]; then
    # --- Create mode: create new task, then attach Slack link ---
    TASK_NAME="$task_name"
    PROJECT_NAME="$project_name"

    if [ -n "$PROJECT_NAME" ]; then
        TARGET_DIR="$TASK_DIR/$PROJECT_NAME"
        mkdir -p "$TARGET_DIR"
    else
        TARGET_DIR="$TASK_DIR"
    fi

    # Sanitize filename
    FILENAME=$(echo "$TASK_NAME" | sed 's/[\/:\\|]/-/g')
    TASK_FILE="$TARGET_DIR/$FILENAME.md"

    # Build projects array for frontmatter
    if [ -n "$PROJECT_NAME" ]; then
        PROJECTS_LINE="projects:\n  - \"[[$PROJECT_NAME]]\""
    else
        PROJECTS_LINE="projects: []"
    fi

    LINK_LINE="- [$TIMESTAMP]($SLACK_URL)"

    cat > "$TASK_FILE" << EOF
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

## Slack

$LINK_LINE
EOF

    # Notification
    if [ -n "$PROJECT_NAME" ]; then
        osascript -e "display notification \"$TASK_NAME in $PROJECT_NAME\" with title \"Task Created & Slack Link Added\" sound name \"Pop\""
    else
        osascript -e "display notification \"$TASK_NAME\" with title \"Task Created & Slack Link Added\" sound name \"Pop\""
    fi
else
    # --- Attach mode: add Slack link to existing task ---
    TASK_FILE="$task_path"
    if [ -z "$TASK_FILE" ] || [ ! -f "$TASK_FILE" ]; then
        osascript -e "display notification \"Task file not found\" with title \"Error\" sound name \"Basso\""
        exit 1
    fi

    # Check for duplicate
    if grep -qF "$SLACK_URL" "$TASK_FILE"; then
        TASK_NAME=$(basename "$TASK_FILE" .md)
        osascript -e "display notification \"Link already exists in $TASK_NAME\" with title \"Duplicate\" sound name \"Basso\""
        exit 0
    fi

    LINK_LINE="- [$TIMESTAMP]($SLACK_URL)"

    # Check if ## Slack section exists
    if grep -q '^## Slack' "$TASK_FILE"; then
        # Find the line number of ## Slack
        SLACK_LINE=$(grep -n '^## Slack' "$TASK_FILE" | head -1 | cut -d: -f1)

        # Find the next ## heading after ## Slack (if any)
        NEXT_SECTION=$(awk -v start="$SLACK_LINE" 'NR > start && /^## / { print NR; exit }' "$TASK_FILE")

        if [ -n "$NEXT_SECTION" ]; then
            # Insert before the next section (with blank line)
            INSERT_LINE=$((NEXT_SECTION - 1))
            # Use temp file for safe editing
            TMPFILE=$(mktemp)
            awk -v insert="$INSERT_LINE" -v line="$LINK_LINE" '
                NR == insert { print line }
                { print }
            ' "$TASK_FILE" > "$TMPFILE"
            mv "$TMPFILE" "$TASK_FILE"
        else
            # ## Slack is the last section, append to end
            # Ensure file ends with newline
            [ -n "$(tail -c 1 "$TASK_FILE")" ] && echo "" >> "$TASK_FILE"
            echo "$LINK_LINE" >> "$TASK_FILE"
        fi
    else
        # No ## Slack section — create it at end of file
        # Ensure file ends with newline
        [ -n "$(tail -c 1 "$TASK_FILE")" ] && echo "" >> "$TASK_FILE"
        echo "" >> "$TASK_FILE"
        echo "## Slack" >> "$TASK_FILE"
        echo "" >> "$TASK_FILE"
        echo "$LINK_LINE" >> "$TASK_FILE"
    fi

    # Update dateModified in frontmatter
    if grep -q '^dateModified:' "$TASK_FILE"; then
        sed -i '' "s/^dateModified: .*/dateModified: $NOW/" "$TASK_FILE"
    fi

    # Notification
    TASK_NAME=$(basename "$TASK_FILE" .md)
    osascript -e "display notification \"Slack link added to $TASK_NAME\" with title \"Link Attached\" sound name \"Pop\""
fi
