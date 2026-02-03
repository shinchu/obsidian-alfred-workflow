#!/bin/bash
# obsidian-task-projects.sh - List projects for Alfred Script Filter

# Load configuration
CONFIG_FILE="$HOME/.config/obsidian-workflow/config"
if [ ! -f "$CONFIG_FILE" ]; then
    echo '{"items":[{"title":"Config not found","subtitle":"Please create ~/.config/obsidian-workflow/config"}]}'
    exit 0
fi
source "$CONFIG_FILE"

TASK_DIR="$VAULT/TaskNotes/Tasks"
INPUT="$1"

# Parse input: "task name > filter" or "task name>filter" or just "task name"
if [[ "$INPUT" == *">"* ]]; then
    TASK_NAME="${INPUT%%>*}"
    TASK_NAME="${TASK_NAME% }"  # trim trailing space
    FILTER="${INPUT#*>}"
    FILTER="${FILTER# }"  # trim leading space
    FILTER_LOWER=$(echo "$FILTER" | tr '[:upper:]' '[:lower:]')
else
    TASK_NAME="$INPUT"
    FILTER=""
    FILTER_LOWER=""
fi

# Escape special characters for JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

ESCAPED_TASK=$(escape_json "$TASK_NAME")

# Build JSON for Alfred Script Filter
echo -n '{"items":['

FIRST=true

# Helper function to add item
add_item() {
    local title="$1"
    local project="$2"
    local match="$3"

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo -n ','
    fi

    local escaped_title=$(escape_json "$title")
    local escaped_project=$(escape_json "$project")

    if [ -z "$project" ]; then
        echo -n '{"title":"'"$escaped_title"'","subtitle":"Create: '"$ESCAPED_TASK"'","arg":"create","variables":{"task_name":"'"$ESCAPED_TASK"'","project_name":""},"icon":{"path":"icons/task.png"}}'
    else
        echo -n '{"title":"'"$escaped_title"'","subtitle":"Create: '"$ESCAPED_TASK"'","arg":"create","variables":{"task_name":"'"$ESCAPED_TASK"'","project_name":"'"$escaped_project"'"},"icon":{"path":"icons/folder.png"}}'
    fi
}

# Check if project matches filter (case-insensitive)
matches_filter() {
    local name="$1"
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    [[ "$name_lower" == *"$FILTER_LOWER"* ]]
}

# First item: create in root (no project)
if [ -z "$FILTER" ] || matches_filter "No Project"; then
    add_item "(No Project)" "" ""
fi

# List project directories
while IFS= read -r dir; do
    PROJECT_NAME=$(basename "$dir")
    if [ -z "$FILTER" ] || matches_filter "$PROJECT_NAME"; then
        add_item "$PROJECT_NAME" "$PROJECT_NAME" "$PROJECT_NAME"
    fi
done < <(find "$TASK_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

# If no results, show hint
if [ "$FIRST" = true ]; then
    echo -n '{"title":"No matching projects","subtitle":"Try a different filter after >","valid":false}'
fi

echo ']}'
