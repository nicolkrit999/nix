# Tmux Reference Guide

> **Note:** **`Alt`** = the **`Meta`** (`M-`) key. Most bindings work **without a prefix** — just press `Alt + key` directly.
> The classic tmux prefix is **`Ctrl + b`**, used only for a handful of standard commands listed at the bottom.

---

## Quick Reference Card

| Category | Key | Action |
| :------- | :-- | :----- |
| **Splits** | `Alt + v` | Split vertically (left \| right) |
| **Splits** | `Alt + h` | Split horizontally (top / bottom) |
| **Navigate** | `Alt + Arrow` | Move focus between panes |
| **Resize** | `Alt + Shift + Arrow` | Resize current pane |
| **Windows** | `Alt + Enter` | New window (tab) |
| **Windows** | `Alt + 1–9` | Jump to window by number |
| **Windows** | `Ctrl + p / n` | Previous / next window |
| **Pane** | `Alt + c` | Close current pane |
| **Window** | `Alt + q` | Close current window + all its panes |
| **Session** | `Alt + d` | Detach (keep everything running) |
| **Session** | `Alt + Shift + s` | Create a new named session |
| **Session** | `Alt + Shift + q` | Kill entire session (stop everything) |
| **Config** | `Alt + r` | Reload tmux config |

---

## Scenario: "Starting the Work Day"

You open a terminal — tmux starts automatically (configured via `programs.bash`).

```
┌──────────────────────────────────────────────┐
│  Window 1 — main                             │
│                                              │
│  $ _                                         │
│                                              │
│  [1] main                                    │
└──────────────────────────────────────────────┘
```

**Common first steps:**

| I want to... | Key | Result |
| :----------- | :-- | :----- |
| Open a second terminal tab | `Alt + Enter` | Creates Window 2 |
| Name the session | `Ctrl + b`, then `$` | Rename "0" → "work" |
| Split my screen for code + output | `Alt + v` | Left pane + right pane |
| Reload config after a change | `Alt + r` | Applies new settings live |

---

## Scenario: "Writing & Running Code"

### Vertical split (side by side)

Press **`Alt + v`** to split vertically. Your screen becomes:

```
┌───────────────────┬───────────────────┐
│                   │                   │
│   Editor / Code   │  Terminal Output  │
│                   │                   │
│   $ nvim main.py  │  $ python main.py │
│                   │                   │
└───────────────────┴───────────────────┘
```

### Horizontal split (stacked)

Press **`Alt + h`** to split horizontally. Your screen becomes:

```
┌───────────────────────────────────────┐
│                                       │
│           Editor / Code               │
│           $ nvim main.py              │
│                                       │
├───────────────────────────────────────┤
│           $ tail -f app.log           │
└───────────────────────────────────────┘
```

### Combining both

Start with `Alt + v`, then in the right pane press `Alt + h`:

```
┌───────────────────┬───────────────────┐
│                   │  $ python main.py │
│   Editor / Code   ├───────────────────┤
│   $ nvim main.py  │  $ tail -f logs   │
│                   │                   │
└───────────────────┴───────────────────┘
```

> **Tip:** Splits always open in the **current pane's directory** — no need to `cd` again.

### Navigating & Resizing Panes

| I want to... | Key | Notes |
| :----------- | :-- | :---- |
| Move focus left | `Alt + ←` | |
| Move focus right | `Alt + →` | |
| Move focus up | `Alt + ↑` | |
| Move focus down | `Alt + ↓` | |
| Make pane wider | `Alt + Shift + →` | +5 columns per press |
| Make pane narrower | `Alt + Shift + ←` | -5 columns per press |
| Make pane taller | `Alt + Shift + ↑` | +3 rows per press |
| Make pane shorter | `Alt + Shift + ↓` | -3 rows per press |

---

## Scenario: "Managing Multiple Tasks (Windows)"

Windows are like browser tabs — each can have its own set of panes.

```
┌──────────────────────────────────────────────────────┐
│  [1] frontend  [2] backend  [3] database  [4] logs   │
│                    ↑ active                          │
└──────────────────────────────────────────────────────┘
```

> Windows are **numbered from 1** (not 0) in this config.

| I want to... | Key | Notes |
| :----------- | :-- | :---- |
| Open a new window | `Alt + Enter` | Appears as next number in bar |
| Switch to window 1 | `Alt + 1` | Works for 1–9 |
| Switch to window 3 | `Alt + 3` | |
| Go to previous window | `Ctrl + b`, then `Ctrl + p` | Cycles left |
| Go to next window | `Ctrl + b`, then `Ctrl + n` | Cycles right |
| Close just this pane | `Alt + c` | Other panes in the window stay |
| Close the whole window | `Alt + q` | All panes inside are destroyed |

**Example workflow:**

```
Alt + Enter        → Window 2 (backend server)
  $ cargo run

Alt + Enter        → Window 3 (logs)
  $ journalctl -f

Alt + 1            → Back to Window 1 (frontend)
Alt + 2            → Jump straight to backend
```

---

## Scenario: "Working on Multiple Projects (Sessions)"

Sessions are completely separate workspaces. Each has its own windows and panes.

```
Sessions:
  ● work       (4 windows)
  ○ side-proj  (2 windows)
  ○ server     (1 window)
```

| I want to... | Key / Command | Notes |
| :----------- | :------------ | :---- |
| Create a new session | `Alt + Shift + s` → type name → Enter | Switches to the new session |
| List & switch sessions | `Ctrl + b`, then `s` | Arrow keys to select |
| Rename current session | `Ctrl + b`, then `$` | |
| Detach (leave running) | `Alt + d` | Terminal closes, session stays alive |
| Reattach from terminal | `tmux attach` | Picks up exactly where you left off |
| Kill current session | `Alt + Shift + q` | Destroys all windows in the session |

**Example workflow:**

```bash
# Morning: start work session
Alt + Shift + s → "work"

# Afternoon: start a side project without losing work context
Alt + Shift + s → "side-proj"

# Switch back to work
Ctrl + b, s → select "work"

# End of day: leave everything running
Alt + d
# Terminal closes. Tomorrow:
tmux attach     # or: tmux attach -t work
```

---

## Scenario: "Scrolling & Copying Text"

This config uses **vi key mode** for copy mode.

### Scroll with the mouse

Just use the **mouse wheel** — tmux enters copy mode automatically. Scroll up to read history, scroll down to return to the bottom.

### Copy text

**Mouse method:**
1. Click and drag to select text.
2. Release — the selection is automatically copied to the Wayland clipboard (`wl-copy`).
3. Paste with `Ctrl + Shift + v` (or middle click) in any app.

**Keyboard method (vi copy mode):**

| Step | Key | Action |
| :--- | :-- | :----- |
| Enter copy mode | `Ctrl + b`, then `[` | Cursor appears |
| Move around | `h j k l` or Arrow keys | vi-style movement |
| Jump half page up | `Ctrl + u` | |
| Jump half page down | `Ctrl + d` | |
| Search upward | `/` then type | Press `n` for next match |
| Start selection | `v` | Visual mode |
| Copy selection | `y` | Yanks to clipboard |
| Exit copy mode | `q` or `Escape` | Returns to normal mode |

---

## Scenario: "Leaving / Finishing"

| I want to... | Key | What happens |
| :----------- | :-- | :----------- |
| Step away safely | `Alt + d` | Detaches — all processes keep running in the background |
| Come back later | `tmux attach` | Restores everything exactly as you left it |
| Close one split | `Alt + c` | Kills the focused pane only |
| Close a tab | `Alt + q` | Kills the window and all its panes |
| End the whole session | `Alt + Shift + q` | Kills all windows, all panes, all processes |

> **Rule of thumb:** Use `Alt + d` (detach) when you are done for now but want to resume. Use `Alt + Shift + q` only when you are truly finished with the session.

---

## System & Config

| Key | Action |
| :-- | :----- |
| `Alt + r` | Reloads `~/.config/tmux/tmux.conf` — apply config changes without restarting |
| `Ctrl + b`, then `Ctrl + p` | Go to previous window |
| `Ctrl + b`, then `Ctrl + n` | Go to next window |
| `Ctrl + b`, then `s` | Interactive session switcher |
| `Ctrl + b`, then `$` | Rename current session |
| `Ctrl + b`, then `[` | Enter copy/scroll mode |
| Mouse wheel | Scroll up (enters copy mode automatically) |

---

## Status Bar

The status bar at the bottom shows:

```
┌────────────────────────────────────────────────────────────┐
│ [1] main  [2] backend  [3] logs          dir · session · user · host │
└────────────────────────────────────────────────────────────┘
```

- **Left:** window list with numbers (starting at 1)
- **Right:** current directory · session name · user · hostname
- Themed automatically with **Catppuccin** when enabled in host constants
