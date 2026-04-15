# Tmux Reference Guide

> **Note:** **`Alt`** = the **`Meta`** (`M-`) key. Most bindings work **without a prefix** — just press `Alt + key` directly.
> The classic tmux prefix is **`Ctrl + b`**, used only for built-in commands listed throughout this guide.
- For macOS (darwin) `Alt` is `Option`.

---

## Quick Reference Card

### Custom Binds (no prefix needed)

| Category | Key | Action |
| :------- | :-- | :----- |
| **Splits** | `Alt + w` | Split horizontally (top / bottom) |
| **Splits** | `Alt + e` | Split vertically (left \| right) |
| **Navigate** | `Alt + Arrow` or `Alt + h/j/k/l` | Move focus between panes |
| **Resize** | `Alt + Shift + Arrow` or `Alt + Shift + H/J/K/L` | Resize current pane |
| **Windows** | `Alt + Enter` | New window (tab) |
| **Windows** | `Alt + 1–9` | Jump to window by number |
| **Pane** | `Alt + c` | Close current pane |
| **Window** | `Alt + q` | Close current window + all its panes |
| **Session** | `Alt + d` | Detach (keep everything running) |
| **Session** | `Alt + Shift + s` | Create a new named session |
| **Session** | `Alt + Shift + q` | Kill entire session (stop everything) |
| **Config** | `Alt + r` | Reload tmux config |

### Built-in Commands (prefix: `Ctrl + b`)

| Category | Key | Action |
| :------- | :-- | :----- |
| **Pane** | `Ctrl + b`, `z` | Zoom/unzoom pane (temporary fullscreen) |
| **Pane** | `Ctrl + b`, `!` | Break pane into its own window |
| **Pane** | `Ctrl + b`, `o` | Cycle focus through panes |
| **Pane** | `Ctrl + b`, `{` / `}` | Swap pane with previous / next |
| **Pane** | `Ctrl + b`, `space` | Cycle through pane layouts |
| **Windows** | `Ctrl + b`, `Ctrl + p` | Previous window |
| **Windows** | `Ctrl + b`, `Ctrl + n` | Next window |
| **Windows** | `Ctrl + b`, `,` | Rename current window |
| **Windows** | `Ctrl + b`, `.` | Move/renumber window |
| **Windows** | `Ctrl + b`, `w` | Interactive window/session tree picker |
| **Session** | `Ctrl + b`, `s` | Interactive session switcher |
| **Session** | `Ctrl + b`, `$` | Rename current session |
| **Copy** | `Ctrl + b`, `[` | Enter copy/scroll mode |
| **Command** | `Ctrl + b`, `:` | Open tmux command prompt |

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
| Split my screen for code + output | `Alt + e` | Left pane + right pane |
| Reload config after a change | `Alt + r` | Applies new settings live |

---

## Scenario: "Writing & Running Code"

### Vertical split (side by side)

Press **`Alt + e`** to split vertically (**e**xpand). Your screen becomes:

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

Press **`Alt + w`** to split horizontally (**w**ide). Your screen becomes:

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

Start with `Alt + e`, then in the right pane press `Alt + w`:

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
| Move focus left | `Alt + ←` or `Alt + h` | |
| Move focus right | `Alt + →` or `Alt + l` | |
| Move focus up | `Alt + ↑` or `Alt + k` | |
| Move focus down | `Alt + ↓` or `Alt + j` | |
| Cycle focus through panes | `Ctrl + b`, then `o` | Alternative to arrow keys |
| Make pane wider | `Alt + Shift + →` or `Alt + Shift + L` | +5 columns per press |
| Make pane narrower | `Alt + Shift + ←` or `Alt + Shift + H` | -5 columns per press |
| Make pane taller | `Alt + Shift + ↑` or `Alt + Shift + K` | +3 rows per press |
| Make pane shorter | `Alt + Shift + ↓` or `Alt + Shift + J` | -3 rows per press |

### Pane Zoom

Press **`Ctrl + b`, then `z`** to temporarily fullscreen a pane. The pane expands to fill the entire window. Press the same combo again to restore the original layout. Very useful when you need to see more of one pane without closing the split.

```
Before zoom:                          After Ctrl+b, z:
┌──────────┬──────────┐              ┌─────────────────────┐
│  editor  │  output  │     →       │                     │
│          │          │              │       output        │
└──────────┴──────────┘              │     (zoomed)        │
                                     └─────────────────────┘
```

### Rearranging Panes

| I want to... | Key | Notes |
| :----------- | :-- | :---- |
| Swap pane with previous | `Ctrl + b`, then `{` | Swaps position, not focus |
| Swap pane with next | `Ctrl + b`, then `}` | |
| Cycle pane layout | `Ctrl + b`, then `space` | Rotates: even-horizontal → even-vertical → main-horizontal → main-vertical → tiled |

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
| Browse all windows | `Ctrl + b`, then `w` | Interactive tree picker |
| Rename current window | `Ctrl + b`, then `,` | Type new name, press Enter |
| Move/renumber window | `Ctrl + b`, then `.` | Type target number |
| Close just this pane | `Alt + c` | Other panes in the window stay |
| Close the whole window | `Alt + q` | All panes inside are destroyed |

### Breaking and Rejoining Panes

You can move panes between windows — useful when a split outgrows its space or you want to recombine things.

| I want to... | Key | Notes |
| :----------- | :-- | :---- |
| Break pane into new window | `Ctrl + b`, then `!` | Current pane becomes its own tab |
| Send pane to window N | `Ctrl + b`, `:` → `join-pane -t N` | Pane moves to window N as a split |
| Pull pane from window N | `Ctrl + b`, `:` → `join-pane -s N` | Pulls window N back in as a split |
| Swap window positions | `Ctrl + b`, `:` → `swap-window -t N` | Swaps current window with window N |

**Full break/rejoin workflow:**

```
1. You have a split in window 1:
   ┌──────────┬──────────┐
   │  editor  │  output  │  [1] main
   └──────────┴──────────┘

2. Focus the "output" pane (Alt + →), then break it out:
   Ctrl + b, !
   ┌─────────────────────┐    ┌─────────────────────┐
   │       editor        │    │       output         │
   │                     │    │                      │
   └─────────────────────┘    └─────────────────────┘
   [1] main                   [2] output

3. Later, rejoin it. Go to window 1, then:
   Ctrl + b, :  →  join-pane -s 2
   ┌──────────┬──────────┐
   │  editor  │  output  │  [1] main  (back together)
   └──────────┴──────────┘
```

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
| Browse everything | `Ctrl + b`, then `w` | Shows sessions + windows tree |
| Rename current session | `Ctrl + b`, then `$` | |
| Detach (leave running) | `Alt + d` | Terminal closes, session stays alive |
| Reattach from terminal | `tmux attach` | Picks up exactly where you left off |
| Attach to specific session | `tmux attach -t work` | By session name |
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
| **Movement** | | |
| Move around | `h j k l` or Arrow keys | vi-style movement |
| Word forward / backward | `w` / `b` | Jump by word |
| Start / end of line | `0` / `$` | |
| Top / bottom of buffer | `g` / `G` | |
| Jump half page up | `Ctrl + u` | |
| Jump half page down | `Ctrl + d` | |
| **Searching** | | |
| Search forward | `/` then type | Press `n` for next, `N` for previous |
| Search backward | `?` then type | Press `n` for next, `N` for previous |
| **Selecting & Copying** | | |
| Start selection | `v` | Visual mode (character) |
| Line selection | `V` | Visual line mode |
| Rectangle selection | `Ctrl + v` | Block/column selection |
| Copy selection | `y` | Yanks to Wayland clipboard |
| **Exit** | | |
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

## Tmux Command Prompt

Press **`Ctrl + b`, then `:`** to open the command prompt. Useful commands:

| Command | Action |
| :------ | :----- |
| `join-pane -t N` | Send current pane to window N |
| `join-pane -s N` | Pull pane from window N into current window |
| `swap-window -t N` | Swap current window with window N |
| `move-window -t N` | Renumber current window to N |
| `list-keys` | Show all active keybindings |
| `display-panes` | Flash pane numbers (useful for identifying panes) |

---

## Config Notes

These features are configured in `modules/common/programs/shells/tmux.nix`:

- **Image passthrough** is enabled (`allow-passthrough on`) — terminal file managers like yazi can display image previews inside tmux
- **RGB color support** is active for kitty, alacritty, and xterm-256color terminals
- **Mouse drag** in copy mode automatically copies to the Wayland clipboard via `wl-copy`
- **Windows start at 1** (not 0) — matches keyboard number row
- **Vi key mode** is active — affects copy mode navigation (h/j/k/l, v for select, y for yank)
- **Zero escape time** — no delay after pressing Escape (important for vi/neovim users)
- **Catppuccin theme** applied automatically when enabled in host constants

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
