#!/bin/bash
# install.sh - Install Obsidian Claude workflow

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
WORKFLOW_DIR="$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/obsidian-claude"

echo "🚀 Installing Obsidian Claude Workflow..."

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$WORKFLOW_DIR"

# Copy scripts
echo "📝 Installing scripts to $INSTALL_DIR..."
cp "$SCRIPT_DIR/scripts/"*.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/obsidian-"*.sh

# Copy Alfred workflow
echo "🎩 Installing Alfred workflow..."
cp "$SCRIPT_DIR/info.plist" "$WORKFLOW_DIR/"

echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 Available commands in Alfred:"
echo "   memo [text]  - Add quick memo to Daily note"
echo "   task [text]  - Create new task (scheduled: tomorrow)"
echo "   start [text] - Start tracking work"
echo "   end          - Stop tracking, show duration"
echo "   brief        - Generate morning briefing"
echo "   review       - Generate daily review"
echo ""
echo "⚠️  Please restart Alfred for changes to take effect."
echo "   (Alfred Preferences → Workflows → Reload)"
