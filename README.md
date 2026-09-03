# Quick Notes for Omarchy

A beautiful, fast, keyboard-first scratchpad and note-taking plugin for Omarchy.

Designed to match Omarchy's design language, themes, typography, and borders with zero setup required.

## Features

- **Instant Overlay**: Summoned instantly via `Super + N` or the status bar widget.
- **Smart Bullet Lists**: Type `- ` or `* ` to start a bullet list. Pressing `Enter` continues with the next bullet.
- **Smart Numbered Lists**: Type `1. ` to start a numbered list. Pressing `Enter` automatically increments (`2. `, `3. `, etc.).
- **Smart Task Checklists**: Type `[ ] ` or `- [ ] ` for checklists. Next lines continue with unchecked boxes.
- **Auto-Exit Lists**: Press `Enter` on an empty bullet or number to cleanly exit list mode.
- **Toggle Tasks**: Press `Ctrl + D` or `Ctrl + Enter` to toggle `[ ]` ↔ `[x]` on the current line.
- **Indent / Outdent**: Use `Tab` and `Shift + Tab` to nest or un-nest list items.
- **Omarchy Reminder Integration**: Type e.g. `15m Check the oven` and press `Ctrl + R` (or the **Remind** button) to trigger an Omarchy desktop notification timer!
- **Auto-Save**: Everything you write is automatically saved to `~/.local/state/omarchy/quick-notes.md`.
- **Clipboard Copy**: One-click or `Ctrl + Shift + C` to copy all notes to clipboard.
- **Omarchy Theme Conformance**: Fully integrates with active Omarchy color themes, font scaling, corner rounding, and border specifications.

## Keybindings & Shortcuts

| Shortcut | Action |
|----------|--------|
| `Super + N` | Toggle Quick Notes overlay |
| `Esc` | Close overlay (auto-saved) |
| `Enter` | Create next list/numbered item |
| `Shift + Enter` | Plain newline without list continuation |
| `Tab` | Indent current line (2 spaces) |
| `Shift + Tab` | Outdent current line |
| `Ctrl + D` | Toggle task checkbox (`[ ]` ↔ `[x]`) |
| `Ctrl + R` | Set reminder from current line |
| `Ctrl + Shift + C` | Copy all notes to clipboard |
| `Ctrl + S` | Save notes immediately |

## CLI Usage

You can also control Quick Notes from any terminal:

```bash
notes                    # Toggle overlay
notes open               # Open overlay
notes close              # Close overlay
notes cat                # Print current notes to stdout
notes add "Buy milk"     # Append a line to notes
```
