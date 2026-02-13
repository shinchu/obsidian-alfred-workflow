#!/bin/bash
# obsidian-slack-tasks.sh - List open/in-progress tasks for Slack link attachment

# Load configuration
CONFIG_FILE="$HOME/.config/obsidian-workflow/config"
if [ ! -f "$CONFIG_FILE" ]; then
    echo '{"items":[{"title":"Config not found","subtitle":"Please create ~/.config/obsidian-workflow/config","valid":false}]}'
    exit 0
fi
source "$CONFIG_FILE"

TASK_DIR="$VAULT/TaskNotes/Tasks"
INPUT="$1"

# Check clipboard for Slack URL
CLIPBOARD=$(pbpaste 2>/dev/null)
SLACK_URL_PATTERN='^https://[a-zA-Z0-9_-]+\.slack\.com/archives/'

# Escape special characters for JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

echo -n '{"items":['

FIRST=true

# If clipboard is not a Slack URL, show warning
if ! [[ "$CLIPBOARD" =~ $SLACK_URL_PATTERN ]]; then
    echo -n '{"title":"⚠️ No Slack URL in clipboard","subtitle":"Copy a Slack message permalink first","valid":false,"icon":{"path":"icons/warning.png"}}'
    echo ']}'
    exit 0
fi

# Parse input: "task name > [project_filter]" for create mode
if [[ "$INPUT" == *">"* ]]; then
    # --- Create mode: show project list ---
    TASK_NAME="${INPUT%%>*}"
    TASK_NAME="${TASK_NAME% }"  # trim trailing space
    PROJECT_FILTER="${INPUT#*>}"
    PROJECT_FILTER="${PROJECT_FILTER# }"  # trim leading space
    FILTER_LOWER=$(echo "$PROJECT_FILTER" | tr '[:upper:]' '[:lower:]')

    ESCAPED_TASK=$(escape_json "$TASK_NAME")

    # Check if project matches filter (case-insensitive)
    matches_filter() {
        local name="$1"
        local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
        [[ "$name_lower" == *"$FILTER_LOWER"* ]]
    }

    # First item: create in root (no project)
    if [ -z "$PROJECT_FILTER" ] || matches_filter "No Project"; then
        echo -n '{"title":"(No Project)","subtitle":"Create: '"$ESCAPED_TASK"'","arg":"create","variables":{"task_name":"'"$ESCAPED_TASK"'","project_name":""},"icon":{"path":"icons/task.png"}}'
        FIRST=false
    fi

    # List project directories
    while IFS= read -r dir; do
        PROJECT_NAME=$(basename "$dir")
        if [ -z "$PROJECT_FILTER" ] || matches_filter "$PROJECT_NAME"; then
            if [ "$FIRST" = true ]; then
                FIRST=false
            else
                echo -n ','
            fi
            ESCAPED_PROJECT=$(escape_json "$PROJECT_NAME")
            echo -n '{"title":"'"$ESCAPED_PROJECT"'","subtitle":"Create: '"$ESCAPED_TASK"'","arg":"create","variables":{"task_name":"'"$ESCAPED_TASK"'","project_name":"'"$ESCAPED_PROJECT"'"},"icon":{"path":"icons/folder.png"}}'
        fi
    done < <(find "$TASK_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

    # If no results, show hint
    if [ "$FIRST" = true ]; then
        echo -n '{"title":"No matching projects","subtitle":"Try a different filter after >","valid":false}'
    fi
else
    # --- Attach mode: show existing tasks ---
    QUERY="$INPUT"
    QUERY_LOWER=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')

    # Find tasks with status: open or status: in-progress
    while IFS= read -r filepath; do
        # Skip files with no name (e.g., ".md")
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

        ESCAPED_TITLE=$(escape_json "$TASK_NAME")
        ESCAPED_SUBTITLE=$(escape_json "$SUBTITLE [$STATUS]")
        ESCAPED_PATH=$(escape_json "$filepath")

        echo -n '{"title":"'"$ESCAPED_TITLE"'","subtitle":"'"$ESCAPED_SUBTITLE"'","arg":"attach","variables":{"task_path":"'"$ESCAPED_PATH"'"},"icon":{"path":"icons/task.png"}}'
    done < <(find "$TASK_DIR" -name '*.md' -type f | sort)

    # If no results, show hint
    if [ "$FIRST" = true ]; then
        echo -n '{"title":"No matching tasks","subtitle":"No open/in-progress tasks found","valid":false}'
    fi

    # Hint item for new task creation
    echo -n ',{"title":"➕ New task...","subtitle":"Type: task name > to select project","valid":false,"icon":{"path":"icons/task.png"}}'
fi

echo ']}'
