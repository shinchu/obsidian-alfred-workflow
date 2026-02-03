#!/bin/bash
# obsidian-brief.sh - Generate morning briefing

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
TASK_DIR="$VAULT/TaskNotes/Tasks"

# Create Daily note from template if not exists
if [ ! -f "$DAILY_PATH" ]; then
    cp "$TEMPLATE_PATH" "$DAILY_PATH"
fi

# Create temporary file for briefing content
BRIEF_CONTENT=$(mktemp)
FOCUS_TASKS=$(mktemp)

# Build briefing content
echo "" >> "$BRIEF_CONTENT"
echo "## ☀️ Morning Briefing ($(date +%H:%M))" >> "$BRIEF_CONTENT"
echo "" >> "$BRIEF_CONTENT"

# Today's calendar
echo "### 📅 今日の予定" >> "$BRIEF_CONTENT"
CALENDAR_ARGS=()
for cal in "${CALENDARS[@]}"; do
    CALENDAR_ARGS+=("--calendar" "$cal")
done
CALENDAR_OUTPUT=$(gcalcli agenda "$TODAY" "$TODAY 23:59" --nostarted "${CALENDAR_ARGS[@]}" \
    2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -E "[0-9]{1,2}:[0-9]{2}|^[[:space:]]+[A-Za-z]" | sed 's/^[[:space:]]*//' | sed 's/^[A-Z][a-z][a-z] [A-Z][a-z][a-z] [0-9][0-9]  //')

if [ -n "$CALENDAR_OUTPUT" ]; then
    echo "$CALENDAR_OUTPUT" | while IFS= read -r line; do
        trimmed=$(echo "$line" | sed 's/^[[:space:]]*//')
        if [ -n "$trimmed" ]; then
            echo "- $trimmed" >> "$BRIEF_CONTENT"
        fi
    done
else
    echo "- 予定なし" >> "$BRIEF_CONTENT"
fi
echo "" >> "$BRIEF_CONTENT"

# 🔥 Today's Focus
echo "### 🔥 今日のフォーカス" >> "$BRIEF_CONTENT"

# 1. High priority and urgent tasks first (if any)
while IFS= read -r f; do
    [ -f "$f" ] || continue
    if grep -q "status: open\|status: in-progress" "$f"; then
        if grep -q "priority: high\|priority: urgent" "$f"; then
            TASK_NAME=$(basename "$f" .md)
            REL_PATH=${f#$VAULT/}
            REL_PATH=${REL_PATH%.md}
            echo "🔴 [[$REL_PATH|$TASK_NAME]]" >> "$FOCUS_TASKS"
        fi
    fi
done < <(find "$TASK_DIR" -name "*.md" 2>/dev/null)

# 2. Tasks scheduled for today
while IFS= read -r f; do
    [ -f "$f" ] || continue
    if grep -q "status: open\|status: in-progress" "$f"; then
        SCHEDULED=$(grep "^scheduled:" "$f" | sed 's/scheduled: //')
        if [ "$SCHEDULED" = "$TODAY" ]; then
            if ! grep -q "priority: high\|priority: urgent" "$f"; then
                TASK_NAME=$(basename "$f" .md)
                REL_PATH=${f#$VAULT/}
                REL_PATH=${REL_PATH%.md}
                echo "📌 [[$REL_PATH|$TASK_NAME]]" >> "$FOCUS_TASKS"
            fi
        fi
    fi
done < <(find "$TASK_DIR" -name "*.md" 2>/dev/null)

# 3. Random pick from overdue tasks to fill up to 5
CURRENT_COUNT=$(wc -l < "$FOCUS_TASKS" | tr -d ' ')
NEEDED=$((5 - CURRENT_COUNT))

if [ $NEEDED -gt 0 ]; then
    OVERDUE_TASKS=$(mktemp)
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        if grep -q "status: open\|status: in-progress" "$f"; then
            if grep -q "priority: high\|priority: urgent" "$f"; then
                continue
            fi
            SCHEDULED=$(grep "^scheduled:" "$f" | sed 's/scheduled: //')
            if [ "$SCHEDULED" = "$TODAY" ]; then
                continue
            fi
            if [ -n "$SCHEDULED" ] && [[ "$SCHEDULED" < "$TODAY" ]]; then
                TASK_NAME=$(basename "$f" .md)
                REL_PATH=${f#$VAULT/}
                REL_PATH=${REL_PATH%.md}
                echo "⏰ [[$REL_PATH|$TASK_NAME]]" >> "$OVERDUE_TASKS"
            fi
        fi
    done < <(find "$TASK_DIR" -name "*.md" 2>/dev/null)
    
    if [ -s "$OVERDUE_TASKS" ]; then
        sort -R "$OVERDUE_TASKS" | head -n $NEEDED >> "$FOCUS_TASKS"
    fi
    rm "$OVERDUE_TASKS"
fi

if [ -s "$FOCUS_TASKS" ]; then
    while IFS= read -r line; do
        echo "- $line" >> "$BRIEF_CONTENT"
    done < "$FOCUS_TASKS"
else
    echo "- タスクなし 🎉" >> "$BRIEF_CONTENT"
fi
rm "$FOCUS_TASKS"
echo "" >> "$BRIEF_CONTENT"

# Summary
IN_PROGRESS_COUNT=$(find "$TASK_DIR" -name "*.md" -exec grep -l "status: in-progress" {} \; 2>/dev/null | wc -l | tr -d ' ')
echo "### 📊 サマリー" >> "$BRIEF_CONTENT"
echo "- 🔄 進行中: ${IN_PROGRESS_COUNT}件" >> "$BRIEF_CONTENT"

OVERDUE_COUNT=0
while IFS= read -r f; do
    [ -f "$f" ] || continue
    if grep -q "status: open\|status: in-progress" "$f"; then
        SCHEDULED=$(grep "^scheduled:" "$f" | sed 's/scheduled: //')
        if [ -n "$SCHEDULED" ] && [[ "$SCHEDULED" < "$TODAY" ]]; then
            OVERDUE_COUNT=$((OVERDUE_COUNT + 1))
        fi
    fi
done < <(find "$TASK_DIR" -name "*.md" 2>/dev/null)

if [ $OVERDUE_COUNT -gt 0 ]; then
    echo "- ⚠️ 期限切れ: ${OVERDUE_COUNT}件" >> "$BRIEF_CONTENT"
else
    echo "- ✨ 期限切れ: なし" >> "$BRIEF_CONTENT"
fi

# Insert after "All Tasks" link line (first line containing "tasks-default.base")
# Create new file with briefing inserted
TEMP_DAILY=$(mktemp)
INSERTED=false

while IFS= read -r line || [ -n "$line" ]; do
    echo "$line" >> "$TEMP_DAILY"
    if [[ "$line" == *"tasks-default.base"* ]] && [ "$INSERTED" = false ]; then
        cat "$BRIEF_CONTENT" >> "$TEMP_DAILY"
        INSERTED=true
    fi
done < "$DAILY_PATH"

# If marker not found, append to end
if [ "$INSERTED" = false ]; then
    cat "$BRIEF_CONTENT" >> "$TEMP_DAILY"
fi

mv "$TEMP_DAILY" "$DAILY_PATH"
rm "$BRIEF_CONTENT"

# Open Daily note in Obsidian
open "obsidian://open?vault=Obsidian&file=Daily%2F$TODAY"

# macOS notification
osascript -e "display notification \"Briefing added to Daily note\" with title \"Morning Briefing\" sound name \"Pop\""
