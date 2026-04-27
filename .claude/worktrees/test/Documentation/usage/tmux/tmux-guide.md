
# 🦁 Tmux Reference Guide (Custom Config)

> **Note:** **`Alt`** corresponds to the **`Meta`** (`M-`) key in your configuration.

## 🛠️ Scenario: "Starting the Work Day"
| I want to... | Key Binding | Why use it? |
| :----------- | :---------- | :---------- |


## 💻 Scenario: "Writing & Running Code"
| I want to...         | Key Binding             | Why use it?                                                                                       |
| :------------------- | :---------------------- | :------------------------------------------------------------------------------------------------ |
| **Run side-by-side** | **Alt + v**             | Splits screen **Vertical** (Left + Right). For example Keep code left, terminal output right.     |
| **Watch logs below** | **Alt + h**             | Splits screen **Horizontal** (Top / Bottom). Keep code Top, watch logs Bottom.                    |
| **Switch Focus**     | **Alt + Arrow**         | Jump between your Code pane (left) and your Terminal output pane (right) without using the mouse. |
| **Adjust Layout**    | **Alt + Shift + Arrow** | Resizes the current pane. Useful if your code needs more width.                                   |

## 🗂️ Scenario: "Managing Clutter"
| I want to...          | Key Binding     | Why use it?                                                                                                                                                    |
| :-------------------- | :-------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Start new project** | **Alt + Enter** | Creates a fresh **Window** (Tab). Use this to separate "Backend Work" from "Database Work". The number of panes remains the same, the previous ones are hidden |
| **Switch Context**    | **Alt + 1/9**   | Instantly flip between Window 1 (Code) and Window 2 (Database).                                                                                                |
| **Close a Split**     | **Alt + c**     | **Kill Pane**. Closes just the specific pane you are focused on. If there are hidden panes then they are not closed                                            |
| **Close a Window**    | **Alt + q**     | **Kill Window**. Closes the entire current tab and all splits inside it.                                                                                       |

## 🏃 Scenario: "Leaving / Finishing"
| I want to...        | Key Binding              | Why use it?                                                                              |
| :------------------ | :----------------------- | :--------------------------------------------------------------------------------------- |
| **Save & Leave**    | **Ctrl + b**, then **d** | **"Detach"**. Hides Tmux but keeps processes running. Safe to close terminal window.     |
| **Rejoin**          | `tmux attach`            | Run this in a new terminal to get back exactly where you left off.                       |
| **Quit Everything** | **Alt + Shift + q**      | **"Kill Session"**. Destroys all windows and stops all programs. Use only when finished. |


## 🔀 Scenario: "Working on Multiple Projects"
| I want to...                  | Action / Command                                                                                                       | Why use it?                                                                                        |
| :---------------------------- | :--------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------- |
| **Create separate workspace** | **1.** Open Terminal (Auto-joins "main")<br>**2.** Type (`Alt`+`Shift` + `s`)<br>**3.** Then type the new session name | Keeps your "Side Project" windows completely separate from your "Main" work.                       |
| **Switch Sessions**           | **Ctrl + b**, then **s**                                                                                               | Opens a **Menu List** of all your running sessions. Use arrows to choose which project to work on. |
| **Rename Session**            | **Ctrl + b**, then **$**                                                                                               | Renames the current session (e.g., rename "main" to "work"). Helps you stay organized in the list. |




## ⚙️ System Commands
| Key Binding     | Action                                           |
| :-------------- | :----------------------------------------------- |
| **Alt + r**     | Reloads `tmux.conf` (if you changed settings).   |
| **Ctrl + p**    | Go to Previous Window.                           |
| **Ctrl + n**    | Go to Next Window.                               |
| **Mouse Wheel** | Scroll up/down (enters Copy Mode automatically). |

