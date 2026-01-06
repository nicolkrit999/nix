{ pkgs, ... }:
{
  programs.yazi.keymap = {

    # -----------------------------------------------------------------------
    # ⌨️ KEYMAP.TOML CONFIGURATION
    # -----------------------------------------------------------------------

    mgr.prepend_keymap = [
      {
        on = [ "<Esc>" ];
        run = "escape";
        desc = "Exit visual mode, clear selection, or cancel search";
      }
      {
        on = [ "q" ];
        run = "quit";
        desc = "Quit the process";
      }
      {
        on = [ "Q" ];
        run = "quit --no-cwd-file";
        desc = "Quit without outputting cwd-file";
      }
      {
        on = [ "<C-c>" ];
        run = "close";
        desc = "Close the current tab, or quit if it's last";
      }
      {
        on = [ "<C-z>" ];
        run = "suspend";
        desc = "Suspend the process";
      }

      # Hopping
      {
        on = [ "k" ];
        run = "arrow -1";
        desc = "Previous file";
      }
      {
        on = [ "j" ];
        run = "arrow 1";
        desc = "Next file";
      }
      {
        on = [ "<Up>" ];
        run = "arrow -1";
        desc = "Previous file";
      }
      {
        on = [ "<Down>" ];
        run = "arrow 1";
        desc = "Next file";
      }
      {
        on = [
          "g"
          "g"
        ];
        run = "arrow top";
        desc = "Go to top";
      }
      {
        on = [ "G" ];
        run = "arrow bot";
        desc = "Go to bottom";
      }

      # Navigation
      {
        on = [ "h" ];
        run = "leave";
        desc = "Back to the parent directory";
      }
      {
        on = [ "l" ];
        run = "enter";
        desc = "Enter the child directory";
      }
      {
        on = [ "H" ];
        run = "back";
        desc = "Back to previous directory";
      }
      {
        on = [ "L" ];
        run = "forward";
        desc = "Forward to next directory";
      }

      # Toggle
      {
        on = [ "<Space>" ];
        run = [
          "toggle"
          "arrow 1"
        ];
        desc = "Toggle the current selection state";
      }
      {
        on = [ "<C-a>" ];
        run = "toggle_all --state=on";
        desc = "Select all files";
      }
      {
        on = [ "<C-r>" ];
        run = "toggle_all";
        desc = "Invert selection of all files";
      }

      # Operations
      {
        on = [ "o" ];
        run = "open";
        desc = "Open selected files";
      }
      {
        on = [ "O" ];
        run = "open --interactive";
        desc = "Open selected files interactively";
      }
      {
        on = [ "<Enter>" ];
        run = "open";
        desc = "Open selected files";
      }
      {
        on = [ "y" ];
        run = "yank";
        desc = "Yank selected files (copy)";
      }
      {
        on = [ "x" ];
        run = "yank --cut";
        desc = "Yank selected files (cut)";
      }
      {
        on = [ "p" ];
        run = "paste";
        desc = "Paste yanked files";
      }
      {
        on = [ "P" ];
        run = "paste --force";
        desc = "Paste yanked files (overwrite)";
      }
      {
        on = [ "d" ];
        run = "remove";
        desc = "Trash selected files";
      }
      {
        on = [ "D" ];
        run = "remove --permanently";
        desc = "Permanently delete selected files";
      }
      {
        on = [ "a" ];
        run = "create";
        desc = "Create a file (ends with / for directories)";
      }
      {
        on = [ "r" ];
        run = "rename --cursor=before_ext";
        desc = "Rename selected file(s)";
      }
      {
        on = [ "." ];
        run = "hidden toggle";
        desc = "Toggle the visibility of hidden files";
      }
      {
        on = [ "s" ];
        run = "search fd";
        desc = "Search files by name via fd";
      }
      {
        on = [ "S" ];
        run = "search rg";
        desc = "Search files by content via ripgrep";
      }
      {
        on = [ "z" ];
        run = "plugin fzf";
        desc = "Jump to a file/directory via fzf";
      }
      {
        on = [ "Z" ];
        run = "plugin zoxide";
        desc = "Jump to a directory via zoxide";
      }

      # Goto
      {
        on = [
          "g"
          "h"
        ];
        run = "cd ~";
        desc = "Go home";
      }
      {
        on = [
          "g"
          "c"
        ];
        run = "cd ~/.config";
        desc = "Go ~/.config";
      }
      {
        on = [
          "g"
          "d"
        ];
        run = "cd ~/Downloads";
        desc = "Go ~/Downloads";
      }
      {
        on = [
          "g"
          "<Space>"
        ];
        run = "cd --interactive";
        desc = "Jump interactively";
      }

      # Tabs
      {
        on = [ "t" ];
        run = "tab_create --current";
        desc = "Create a new tab with CWD";
      }
      {
        on = [ "1" ];
        run = "tab_switch 0";
        desc = "Switch to first tab";
      }
      {
        on = [ "2" ];
        run = "tab_switch 1";
        desc = "Switch to second tab";
      }
      {
        on = [ "[" ];
        run = "tab_switch -1 --relative";
        desc = "Switch to previous tab";
      }
      {
        on = [ "]" ];
        run = "tab_switch 1 --relative";
        desc = "Switch to next tab";
      }

      # Help
      {
        on = [ "~" ];
        run = "help";
        desc = "Open help";
      }
    ];

    tasks.prepend_keymap = [
      {
        on = [ "<Esc>" ];
        run = "close";
        desc = "Close task manager";
      }
      {
        on = [ "w" ];
        run = "close";
        desc = "Close task manager";
      }
      {
        on = [ "k" ];
        run = "arrow -1";
        desc = "Previous task";
      }
      {
        on = [ "j" ];
        run = "arrow 1";
        desc = "Next task";
      }
      {
        on = [ "<Enter>" ];
        run = "inspect";
        desc = "Inspect the task";
      }
      {
        on = [ "x" ];
        run = "cancel";
        desc = "Cancel the task";
      }
    ];

    input.prepend_keymap = [
      {
        on = [ "<C-c>" ];
        run = "close";
        desc = "Cancel input";
      }
      {
        on = [ "<Enter>" ];
        run = "close --submit";
        desc = "Submit input";
      }
      {
        on = [ "<Esc>" ];
        run = "escape";
        desc = "Back to normal mode, or cancel input";
      }
      {
        on = [ "<Backspace>" ];
        run = "backspace";
        desc = "Delete character";
      }
    ];
  };
}
