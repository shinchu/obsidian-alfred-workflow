#!/bin/bash
# obsidian-done-tasks.sh - List open/in-progress tasks for completion

# Load configuration
CONFIG_FILE="$HOME/.config/obsidian-workflow/config"
if [ ! -f "$CONFIG_FILE" ]; then
    echo '{"items":[{"title":"Config not found","subtitle":"Please create ~/.config/obsidian-workflow/config","valid":false}]}'
    exit 0
fi
source "$CONFIG_FILE"

TASK_DIR="$VAULT/TaskNotes/Tasks"
QUERY="$1"
QUERY_LOWER=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')

# Escape special characters for JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

echo -n '{"items":['

FIRST=true

# Find tasks with status: open or status: in-progress
while IFS= read -r filepath; do
    BASENAME=$(basename "$filepath")
    if [ "$BASENAME" = ".md" ]; then
        continue
    fi

    # Read status from frontmatter
    STATUS=$(sed -n '/^---$/,/^---$/{ s/^status: *//p; }' "$filepath")

    if [ "$STATUS" != "open" ] && [ "$STATUS" != "in-progress" ]; then
        continue
    fi

    # Extract task name and project from path
    RELPATH="${filepath#$TASK_DIR/}"
    TASK_NAME=$(basename "$filepath" .md)
    DIRPART=$(dirname "$RELPATH")

    if [ "$DIRPART" = "." ]; then
        PROJECT=""
        SUBTITLE="(No Project)"
    else
        PROJECT="$DIRPART"
        SUBTITLE="$PROJECT"
    fi

    # Filter by query (match task name or project name, case-insensitive)
    if [ -n "$QUERY" ]; then
        TASK_LOWER=$(echo "$TASK_NAME" | tr '[:upper:]' '[:lower:]')
        PROJECT_LOWER=$(echo "$PROJECT" | tr '[:upper:]' '[:lower:]')
        if [[ "$TASK_LOWER" != *"$QUERY_LOWER"* ]] && [[ "$PROJECT_LOWER" != *"$QUERY_LOWER"* ]]; then
            continue
        fi
    fi

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo -n ','
    fi

    # Status icon
    if [ "$STATUS" = "in-progress" ]; then
        ICON="🔵"
    else
        ICON="⚪"
    fi

    ESCAPED_TITLE=$(escape_json "$TASK_NAME")
    ESCAPED_SUBTITLE=$(escape_json "$SUBTITLE [$STATUS]")
    ESCAPED_PATH=$(escape_json "$filepath")

    echo -n '{"title":"'"$ICON"' '"$ESCAPED_TITLE"'","subtitle":"'"$ESCAPED_SUBTITLE"'","arg":"'"$ESCAPED_PATH"'","icon":{"path":"icons/task.png"}}'
done < <(find "$TASK_DIR" -name '*.md' -type f | sort)

# If no results, show hint
if [ "$FIRST" = true ]; then
    echo -n '{"title":"No open tasks","subtitle":"All tasks are already completed","valid":false}'
fi

echo ']}'
