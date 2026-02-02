#!/bin/bash
# obsidian-memo.sh - Add quick memo to Daily note

VAULT="$HOME/Dropbox/Sync/Obsidian"
TODAY=$(date +%Y-%m-%d)
DAILY_PATH="$VAULT/Daily/$TODAY.md"
TEMPLATE_PATH="$VAULT/Templates/Daily.md"
TIME=$(date +%H:%M)
MEMO="$1"

# Create Daily note if not exists
if [ ! -f "$DAILY_PATH" ]; then
    cp "$TEMPLATE_PATH" "$DAILY_PATH"
fi

# Append memo to the file (after # Memo section)
echo "- $TIME $MEMO" >> "$DAILY_PATH"

# macOS notification
osascript -e "display notification \"$MEMO\" with title \"Memo Added\" sound name \"Pop\""
