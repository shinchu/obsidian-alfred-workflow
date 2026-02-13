#!/bin/bash
# install.sh - Install Obsidian workflow

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/obsidian-workflow"
ALFRED_CONFIG_DIR="$HOME/Dropbox/Settings/Alfred/Alfred.alfredpreferences"
WORKFLOW_DIR="$ALFRED_CONFIG_DIR/workflows/user.workflow.obsidian-workflow"

echo "Installing Obsidian Workflow..."

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKFLOW_DIR"

# Copy scripts
echo "Installing scripts to $INSTALL_DIR..."
cp "$SCRIPT_DIR/scripts/"*.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/obsidian-"*.sh

# Copy Alfred workflow
echo "Installing Alfred workflow..."
cp "$SCRIPT_DIR/info.plist" "$WORKFLOW_DIR/"

# Setup config file
if [ ! -f "$CONFIG_DIR/config" ]; then
    cp "$SCRIPT_DIR/config.example" "$CONFIG_DIR/config"
    echo ""
    echo "Configuration file created at: $CONFIG_DIR/config"
    echo "Please edit it to set your Obsidian vault path and calendars."
else
    echo "Config file already exists at: $CONFIG_DIR/config"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Edit $CONFIG_DIR/config"
echo "  2. Restart Alfred (Preferences -> Workflows -> Reload)"
echo ""
echo "Available commands in Alfred:"
echo "   memo [text]  - Add quick memo to Daily note"
echo "   task [text]  - Create new task with project selection"
echo "   start [text] - Start tracking work"
echo "   end          - Stop tracking, show duration"
echo "   brief        - Generate morning briefing"
echo "   review       - Generate daily review"
echo "   slack [filter]  - Attach Slack link to a task"
