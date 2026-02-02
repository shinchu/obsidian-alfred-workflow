#!/bin/bash
# obsidian-review.sh - Generate daily review

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

# Create temporary file for review content
REVIEW_CONTENT=$(mktemp)

# Build review content
echo "" >> "$REVIEW_CONTENT"
echo "## 🌙 Daily Review ($(date +%H:%M))" >> "$REVIEW_CONTENT"
echo "" >> "$REVIEW_CONTENT"

# Today's calendar events
echo "### 📅 今日の予定（実績）" >> "$REVIEW_CONTENT"
CALENDAR_ARGS=""
for cal in "${CALENDARS[@]}"; do
    CALENDAR_ARGS="$CALENDAR_ARGS --calendar \"$cal\""
done
CALENDAR_OUTPUT=$(eval gcalcli agenda "$TODAY" "$TODAY 23:59" $CALENDAR_ARGS \
    2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -E "[0-9]{1,2}:[0-9]{2}|^[[:space:]]+[A-Za-z]" | sed 's/^[[:space:]]*//')

if [ -n "$CALENDAR_OUTPUT" ]; then
    echo "$CALENDAR_OUTPUT" | while IFS= read -r line; do
        trimmed=$(echo "$line" | sed 's/^[[:space:]]*//')
        if [ -n "$trimmed" ]; then
            echo "- $trimmed" >> "$REVIEW_CONTENT"
        fi
    done
else
    echo "- 予定なし" >> "$REVIEW_CONTENT"
fi
echo "" >> "$REVIEW_CONTENT"

# Tasks completed today
echo "### ✅ 完了したタスク" >> "$REVIEW_CONTENT"
FOUND_COMPLETED=false
while IFS= read -r f; do
    [ -f "$f" ] || continue
    if grep -q "status: done" "$f"; then
        COMPLETED_DATE=$(grep "^completedDate:" "$f" | sed 's/completedDate: //' | cut -d'T' -f1)
        if [ "$COMPLETED_DATE" = "$TODAY" ]; then
            TASK_NAME=$(basename "$f" .md)
            REL_PATH=${f#$VAULT/}
            REL_PATH=${REL_PATH%.md}
            echo "- [[$REL_PATH|$TASK_NAME]]" >> "$REVIEW_CONTENT"
            FOUND_COMPLETED=true
        fi
    fi
done < <(find "$TASK_DIR" -name "*.md" 2>/dev/null)

if [ "$FOUND_COMPLETED" = false ]; then
    echo "- なし" >> "$REVIEW_CONTENT"
fi
echo "" >> "$REVIEW_CONTENT"

# Work time summary
echo "### ⏱️ 作業時間" >> "$REVIEW_CONTENT"
if [ -f "$DAILY_PATH" ]; then
    WORK_ENTRIES=$(grep "🔴 終了:" "$DAILY_PATH" 2>/dev/null | sed 's/^- [0-9:]*//') 
    if [ -n "$WORK_ENTRIES" ]; then
        echo "$WORK_ENTRIES" | while IFS= read -r line; do
            echo "-$line" >> "$REVIEW_CONTENT"
        done
    else
        echo "- 記録なし" >> "$REVIEW_CONTENT"
    fi
else
    echo "- 記録なし" >> "$REVIEW_CONTENT"
fi
echo "" >> "$REVIEW_CONTENT"

# Insert before "# Memo" line
TEMP_DAILY=$(mktemp)
INSERTED=false

while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" == "# Memo"* ]] && [ "$INSERTED" = false ]; then
        cat "$REVIEW_CONTENT" >> "$TEMP_DAILY"
        INSERTED=true
    fi
    echo "$line" >> "$TEMP_DAILY"
done < "$DAILY_PATH"

# If marker not found, append to end
if [ "$INSERTED" = false ]; then
    cat "$REVIEW_CONTENT" >> "$TEMP_DAILY"
fi

mv "$TEMP_DAILY" "$DAILY_PATH"
rm "$REVIEW_CONTENT"

# Open Daily note in Obsidian
open "obsidian://open?vault=Obsidian&file=Daily%2F$TODAY"

# macOS notification
osascript -e "display notification \"Review added to Daily note\" with title \"Daily Review\" sound name \"Pop\""
