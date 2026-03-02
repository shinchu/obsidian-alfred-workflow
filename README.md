# Obsidian Alfred Workflow

A workflow integrating Obsidian and Alfred to streamline Daily notes, task management, and work time tracking.

## Features

| Command | Description |
|---------|-------------|
| `memo [text]` | Add a quick memo to Daily note |
| `task [filter]` | Search tasks and open in Obsidian, or create new |
| `slk [filter]` | Attach a Slack link to a task (or create a new one) |
| `start [text]` | Start work tracking |
| `end` | End work tracking, calculate duration |
| `brief` | Generate morning briefing |
| `done [filter]` | Mark a task as completed |
| `review` | Generate daily review |

## Requirements

- macOS
- [Alfred](https://www.alfredapp.com/) (Powerpack)
- [Obsidian](https://obsidian.md/)
- [gcalcli](https://github.com/insanum/gcalcli) (for brief and review features)

## Installation

```bash
git clone https://github.com/shinchu/obsidian-claude-workflow.git
cd obsidian-claude-workflow
./install.sh
```

After installation, restart Alfred.

## Configuration

After installation, edit the configuration file:

```bash
~/.config/obsidian-workflow/config
```

### Configuration Options

```bash
# Path to your Obsidian vault
VAULT="$HOME/path/to/your/vault"

# Google Calendar names (for gcalcli)
CALENDARS=(
    "Personal"
    "Work"
    "Family"
)
```

`CALENDARS` is used by the `brief` and `review` commands. If you don't use gcalcli, an empty array `CALENDARS=()` will also work.

### Directory Structure

```
Obsidian/
├── Daily/           # Daily notes location
├── Templates/
│   └── Daily        # Daily note template
└── TaskNotes/
    └── Tasks/       # Task files location
```

## Usage

### Adding a Memo

Type `memo Great idea for the project` in Alfred, and it will be appended to today's Daily note with a timestamp.

```
- 14:30 Great idea for the project
```

### Searching and Opening Tasks

`task` searches existing open/in-progress tasks and opens them in Obsidian.

- `task` → shows all open/in-progress tasks
- `task report` → filters tasks matching "report"
- Select a task → opens it in Obsidian

### Creating a Task

Use `>` to switch to task creation mode with project selection:

- `task Write report >` → shows all projects
- `task Write report > work` → shows only projects matching "work"

Selecting "Create" from search results creates a task without a project.

### Attaching a Slack Link

Copy a Slack message permalink to your clipboard, then use `slk` to attach it to a task.

**Attach to an existing task:**

- `slk` → shows all open/in-progress tasks
- `slk report` → filters tasks matching "report"
- Select a task → Slack link is added under a `## Slack` section

**Create a new task with a Slack link:**

- `slk Fix login bug >` → shows project selection list
- `slk Fix login bug > work` → filters projects matching "work"
- Select a project → task is created with the Slack link attached

### Completing a Task

`done` marks a task as completed.

- `done` → shows all open/in-progress tasks
- `done report` → filters tasks matching "report"
- Select a task → status changes to `done` with a completion timestamp

### Work Time Tracking

1. `start Writing paper` to start work
2. `end` to finish work

Recorded in Daily note as:
```
- 10:00 🟢 Start: Writing paper
- 12:30 🔴 End: Writing paper (2h30m)
```

### Morning Briefing

`brief` generates today's schedule and tasks to focus on:

- 📅 Today's calendar events
- 🔥 Today's focus (high priority, scheduled today, overdue tasks)
- 📊 Task summary

### Daily Review

`review` generates a daily review:

- 📅 Today's events (completed)
- ✅ Completed tasks
- ⏱️ Work time summary

## License

MIT

## Acknowledgments

Created using [Claude Code](https://code.claude.com/docs) and [Wispr Flow](https://wisprflow.ai/).
