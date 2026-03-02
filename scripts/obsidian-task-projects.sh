#!/bin/bash
# obsidian-task-projects.sh - Search existing tasks or list projects for new task creation

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
    MODE="create"
else
    TASK_NAME="$INPUT"
    FILTER=""
    FILTER_LOWER=""
    MODE="search"
fi

# Escape special characters for JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

ESCAPED_TASK=$(escape_json "$TASK_NAME")

# Build JSON for Alfred Script Filter
echo -n '{"items":['

FIRST=true

# Helper: add separator comma
add_comma() {
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo -n ','
    fi
}

# Helper function to add create item
add_create_item() {
    local title="$1"
    local project="$2"

    add_comma

    local escaped_title=$(escape_json "$title")
    local escaped_project=$(escape_json "$project")

    if [ -z "$project" ]; then
        echo -n '{"title":"'"$escaped_title"'","subtitle":"Create: '"$ESCAPED_TASK"'","arg":"create","variables":{"task_name":"'"$ESCAPED_TASK"'","project_name":""},"icon":{"path":"icons/task.png"}}'
    else
        echo -n '{"title":"'"$escaped_title"'","subtitle":"Create: '"$ESCAPED_TASK"'","arg":"create","variables":{"task_name":"'"$ESCAPED_TASK"'","project_name":"'"$escaped_project"'"},"icon":{"path":"icons/folder.png"}}'
    fi
}

# Check if name matches filter (case-insensitive)
matches_filter() {
    local name="$1"
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    [[ "$name_lower" == *"$FILTER_LOWER"* ]]
}

if [ "$MODE" = "search" ]; then
    # Search mode: show matching existing tasks, then create option
    QUERY_LOWER=$(echo "$TASK_NAME" | tr '[:upper:]' '[:lower:]')

    # List matching open/in-progress tasks
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
            PROJECT=""
            SUBTITLE="(No Project)"
        else
            PROJECT="$DIRPART"
            SUBTITLE="$PROJECT"
        fi

        # Filter by query (match task name or project name, case-insensitive)
        if [ -n "$TASK_NAME" ]; then
            TASK_LOWER=$(echo "$FILE_TASK_NAME" | tr '[:upper:]' '[:lower:]')
            PROJECT_LOWER=$(echo "$PROJECT" | tr '[:upper:]' '[:lower:]')
            if [[ "$TASK_LOWER" != *"$QUERY_LOWER"* ]] && [[ "$PROJECT_LOWER" != *"$QUERY_LOWER"* ]]; then
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
        ESCAPED_SUBTITLE=$(escape_json "$SUBTITLE [$STATUS]")
        ESCAPED_PATH=$(escape_json "$filepath")

        echo -n '{"title":"'"$ICON"' '"$ESCAPED_TITLE"'","subtitle":"'"$ESCAPED_SUBTITLE"'","arg":"open","variables":{"task_path":"'"$ESCAPED_PATH"'"},"icon":{"path":"icons/task.png"}}'
    done < <(find "$TASK_DIR" -name '*.md' -type f | sort)

    # Add "Create new task" option at the end (only when query is not empty)
    if [ -n "$TASK_NAME" ]; then
        add_comma
        echo -n '{"title":"➕ Create: '"$ESCAPED_TASK"'","subtitle":"Use > to select project (e.g. task name > project)","arg":"create","variables":{"task_name":"'"$ESCAPED_TASK"'","project_name":""},"icon":{"path":"icons/task.png"}}'
    fi

    # If no results at all
    if [ "$FIRST" = true ]; then
        echo -n '{"title":"No tasks found","subtitle":"Type a name to search or create a task","valid":false}'
    fi
else
    # Create mode (> used): show project list for new task creation

    # First item: create in root (no project)
    if [ -z "$FILTER" ] || matches_filter "No Project"; then
        add_create_item "(No Project)" ""
    fi

    # List project directories
    while IFS= read -r dir; do
        PROJECT_NAME=$(basename "$dir")
        if [ -z "$FILTER" ] || matches_filter "$PROJECT_NAME"; then
            add_create_item "$PROJECT_NAME" "$PROJECT_NAME"
        fi
    done < <(find "$TASK_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

    # If no results, show hint
    if [ "$FIRST" = true ]; then
        echo -n '{"title":"No matching projects","subtitle":"Try a different filter after >","valid":false}'
    fi
fi

echo ']}'
