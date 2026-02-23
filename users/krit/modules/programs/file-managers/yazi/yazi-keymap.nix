{ delib, ... }:
delib.module {
  name = "krit.programs.yazi";

  home.ifEnabled =
    { ... }:
    {
      programs.yazi.keymap = {
        # S = shift, C = control, A = alt
        mgr.prepend_keymap = [
          # -----------------------------------------------------------------------
          # 📦 PLUGIN KEYBINDINGS (Prefix 'b')
          # -----------------------------------------------------------------------
          # 1. Relative Motions
          {
            on = [
              "n"
              "m"
            ];
            run = "plugin relative-motions";
            desc = "📍 Trigger Relative Motion (then type number+dir)";
          }

          {
            on = [ "1" ];
            run = "plugin relative-motions 1";
            desc = "Move in relative steps";
          }
          {
            on = [ "2" ];
            run = "plugin relative-motions 2";
            desc = "Move in relative steps";
          }
          {
            on = [ "3" ];
            run = "plugin relative-motions 3";
            desc = "Move in relative steps";
          }
          {
            on = [ "4" ];
            run = "plugin relative-motions 4";
            desc = "Move in relative steps";
          }
          {
            on = [ "5" ];
            run = "plugin relative-motions 5";
            desc = "Move in relative steps";
          }
          {
            on = [ "6" ];
            run = "plugin relative-motions 6";
            desc = "Move in relative steps";
          }
          {
            on = [ "7" ];
            run = "plugin relative-motions 7";
            desc = "Move in relative steps";
          }
          {
            on = [ "8" ];
            run = "plugin relative-motions 8";
            desc = "Move in relative steps";
          }
          {
            on = [ "9" ];
            run = "plugin relative-motions 9";
            desc = "Move in relative steps";
          }

          # 2. ouch
          {
            on = [ "c" ];
            run = "plugin ouch";
            desc = "Compress with ouch";
          }

          # 3. recycle-bin
          {
            on = [
              "b"
              "r"
            ];
            run = "plugin recycle-bin -- restore";
            desc = "Restore selected files from Trash";
          }
          {
            on = [
              "b"
              "e"
            ];
            run = "plugin recycle-bin -- empty";
            desc = "Empty the entire Trash";
          }
          {
            on = [
              "b"
              "D"
            ];
            run = "plugin recycle-bin -- emptyDays";
            desc = "Empty Trash older than X days";
          }
          {
            on = [
              "b"
              "b"
            ];
            run = "plugin recycle-bin -- open";
            desc = "Open Recycle Bin";
          }

          # -----------------------------------------------------------------------
          # Defaults
          # -----------------------------------------------------------------------
          {
            on = [ "<Esc>" ];
            run = [
              "unyank"
              "toggle_all --state=off"
              "escape"
            ];
            desc = "Clear selection, clipboard, and cancel search";
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
            run = "arrow prev";
            desc = "Previous file (wrapping)";
          }
          {
            on = [ "K" ];
            run = "arrow -5";
            desc = "Move up five files";
          }

          {
            on = [ "j" ];
            run = "arrow next";
            desc = "Next file (wrapping)";
          }
          {
            on = [ "J" ];
            run = "arrow 5 ";
            desc = "Move down five files";
          }

          {
            on = [ "<Up>" ];
            run = "arrow prev ";
            desc = "Previous file (wrapping)";
          }

          {
            on = [ "<S-Up>" ];
            run = "arrow -5 ";
            desc = "Move up five files";
          }

          {
            on = [ "<Down>" ];
            run = "arrow next ";
            desc = "Next file (wrapping)";
          }
          {
            on = [ "<S-Down>" ];
            run = "arrow 5 ";
            desc = "Move down five files";
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
            desc = "Enter file or directory";
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
          # -----------------------------------------------------------------------
          # Built-in Plugins
          # -----------------------------------------------------------------------
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
              "D"
            ];
            run = "cd ~/Documents";
            desc = "Go ~/Documents";
          }
          {
            on = [
              "g"
              "n"
            ];
            run = "cd ~/nixOS";
            desc = "Go ~/nixOS";
          }

          {
            on = [
              "g"
              "p"
            ];
            run = "cd ~/Pictures";
            desc = "Go ~/Pictures";
          }
          {
            on = [
              "g"
              "P"
            ];
            run = "cd ~/nixOS/hosts/nixos-desktop/optional/dev-environments";
            desc = "Go nix dev-environments";
          }

          {
            on = [
              "g"
              "v"
            ];
            run = "cd ~/Videos";
            desc = "Go ~/Videos";
          }
          {
            on = [
              "g"
              "."
            ];
            run = "cd ~/dotfiles";
            desc = "Go ~/dotfiles";
          }
          {
            on = [
              "g"
              "t"
            ];
            run = "cd ~/.local/share/Trash/files";
            desc = "Go to Trash";
          }
          {
            on = [
              "g"
              "m"
              "n"
            ];
            run = "cd /mnt/nicol_nas";
            desc = "Go to the NAS";
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
            on = [ "t" "c" ]; # Press 't' then 'c'
            run = "tab_create --current";
            desc = "Create a new tab with CWD";
          }

          # 1. Absolute Switching
          { on = [ "t" "1" ]; run = "tab_switch 0"; desc = "Switch to first tab"; }
          { on = [ "t" "2" ]; run = "tab_switch 1"; desc = "Switch to second tab"; }
          { on = [ "t" "3" ]; run = "tab_switch 2"; desc = "Switch to third tab"; }
          { on = [ "t" "4" ]; run = "tab_switch 3"; desc = "Switch to fourth tab"; }

          # 2. Relative Switching (Left/Right) - Keeping these fast and single-key
          {
            on = [ "[" ];
            run = "tab_switch -1 --relative";
            desc = "Switch to previous tab (Left)";
          }
          {
            on = [ "]" ];
            run = "tab_switch 1 --relative";
            desc = "Switch to next tab (Right)";
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
    };
}
