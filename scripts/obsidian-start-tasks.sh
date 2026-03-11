#!/bin/bash
# obsidian-start-tasks.sh - Script Filter: list tasks for start command

# Load configuration
CONFIG_FILE="$HOME/.config/obsidian-workflow/config"
if [ ! -f "$CONFIG_FILE" ]; then
    echo '{"items":[{"title":"Config not found","subtitle":"Please create ~/.config/obsidian-workflow/config"}]}'
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

add_comma() {
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo -n ','
    fi
}

# List matching open/in-progress tasks
if [ -d "$TASK_DIR" ]; then
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
        FILE_TASK_NAME=$(basename "$filepath" .md)
        DIRPART=$(dirname "$RELPATH")

        if [ "$DIRPART" = "." ]; then
            SUBTITLE="(No Project) [$STATUS]"
        else
            SUBTITLE="$DIRPART [$STATUS]"
        fi

        # Filter by query
        if [ -n "$QUERY" ]; then
            TASK_LOWER=$(echo "$FILE_TASK_NAME" | tr '[:upper:]' '[:lower:]')
            SUBTITLE_LOWER=$(echo "$SUBTITLE" | tr '[:upper:]' '[:lower:]')
            if [[ "$TASK_LOWER" != *"$QUERY_LOWER"* ]] && [[ "$SUBTITLE_LOWER" != *"$QUERY_LOWER"* ]]; then
                continue
            fi
        fi

        add_comma

        # Status icon
        if [ "$STATUS" = "in-progress" ]; then
            ICON="🔵"
        else
            ICON="⚪"
        fi

        ESCAPED_TITLE=$(escape_json "$FILE_TASK_NAME")
        ESCAPED_SUBTITLE=$(escape_json "$SUBTITLE")
        ESCAPED_PATH=$(escape_json "$filepath")

        echo -n '{"title":"'"$ICON"' '"$ESCAPED_TITLE"'","subtitle":"'"$ESCAPED_SUBTITLE"'","arg":"'"$ESCAPED_TITLE"'","variables":{"task_path":"'"$ESCAPED_PATH"'"},"icon":{"path":"icons/task.png"}}'
    done < <(find "$TASK_DIR" -name '*.md' -type f | sort)
fi

# Add free input option (when query is not empty)
if [ -n "$QUERY" ]; then
    add_comma
    ESCAPED_QUERY=$(escape_json "$QUERY")
    echo -n '{"title":"✏️ '"$ESCAPED_QUERY"'","subtitle":"Start with free text","arg":"'"$ESCAPED_QUERY"'","variables":{"task_path":""},"icon":{"path":"icons/task.png"}}'
fi

# If no results at all
if [ "$FIRST" = true ]; then
    echo -n '{"title":"No tasks found","subtitle":"Type to search tasks or enter free text","valid":false}'
fi

echo ']}'
