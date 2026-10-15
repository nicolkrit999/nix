{ delib
, lib
, pkgs
, ...
}:
let
  ordinals = [
    "first"
    "second"
    "third"
    "fourth"
    "fifth"
    "sixth"
    "seventh"
    "eighth"
    "ninth"
  ];

  # Top-level on purpose: consumed as a vim-style count prefix before a direction key.
  relativeMotions = lib.genList
    (i: {
      on = [ (toString (i + 1)) ];
      run = "plugin relative-motions ${toString (i + 1)}";
      desc = "Move in relative steps";
    })
    9;

  tabSwitch = lib.genList
    (i: {
      on = [ "t" (toString (i + 1)) ];
      run = "tab_switch ${toString i}";
      desc = "Switch to ${builtins.elemAt ordinals i} tab";
    })
    9;

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
delib.module {
  name = "krit.programs.yazi";

  home.ifEnabled =
    { myconfig, ... }:
    {
      # `mk` creates its arguments after the shell has brace-expanded them:
      # a trailing "/" makes a directory, anything else a file (parents are
      # created, existing files are left untouched).
      home.packages = [
        (pkgs.writeShellScriptBin "mk" ''
          for p in "$@"; do
            case "$p" in
              */) mkdir -p -- "$p" ;;
              *) mkdir -p -- "$(dirname -- "$p")" && touch -- "$p" ;;
            esac
          done
        '')
      ];

      programs.yazi.keymap = {
        # S = shift, C = control, A = alt
        mgr.prepend_keymap = relativeMotions ++ [
          # Plugins submenu ('u'); z/Z (fzf/zoxide) and d (smart-remove) stay
          # top-level because two-key latency isn't worth it for them.
          {
            on = [
              "u"
              "c"
            ];
            run = "plugin ouch";
            desc = "Compress with ouch";
          }
          {
            on = [
              "u"
              "n"
            ];
            run = "plugin relative-motions";
            desc = "📍 Trigger Relative Motion (then type number+dir)";
          }
          {
            on = [
              "u"
              "b"
            ];
            run = "plugin recycle-bin -- open";
            desc = "Open Recycle Bin";
          }
          {
            on = [
              "u"
              "r"
            ];
            run = "plugin recycle-bin -- restore";
            desc = "Restore selected files from Trash";
          }
          {
            on = [
              "u"
              "e"
            ];
            run = "plugin recycle-bin -- empty";
            desc = "Empty the entire Trash";
          }
          {
            on = [
              "u"
              "D"
            ];
            run = "plugin recycle-bin -- emptyDays";
            desc = "Empty Trash older than X days";
          }

          # faster-piper preview scrolling (Alt-modified, no conflicts)
          {
            on = [ "<A-Up>" ];
            run = "seek -1";
            desc = "Scroll preview up";
          }
          {
            on = [ "<A-Down>" ];
            run = "seek +1";
            desc = "Scroll preview down";
          }
          {
            on = [ "<A-PageUp>" ];
            run = "seek -15";
            desc = "Scroll preview page up";
          }
          {
            on = [ "<A-PageDown>" ];
            run = "seek +15";
            desc = "Scroll preview page down";
          }
          {
            on = [ "<A-Home>" ];
            run = "seek -10000";
            desc = "Scroll preview to the top";
          }
          {
            on = [ "<A-End>" ];
            run = "seek +10000";
            desc = "Scroll preview to the bottom";
          }
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
            run = "arrow 5";
            desc = "Move down five files";
          }
          {
            on = [ "<Up>" ];
            run = "arrow prev";
            desc = "Previous file (wrapping)";
          }
          {
            on = [ "<S-Up>" ];
            run = "arrow -5";
            desc = "Move up five files";
          }
          {
            on = [ "<Down>" ];
            run = "arrow next";
            desc = "Next file (wrapping)";
          }
          {
            on = [ "<S-Down>" ];
            run = "arrow 5";
            desc = "Move down five files";
          }
          {
            on = [ "<Enter>" ];
            run = "open";
            desc = "Enter file or directory";
          }
          {
            on = [ "P" ];
            run = "paste --force";
            desc = "Paste yanked files (overwrite)";
          }
          {
            on = [ "d" ];
            run = "plugin smart-remove";
            desc = "Trash selected files (NAS-aware)";
          }
          {
            on = [ "A" ];
            run = "shell 'mk ' --interactive --cursor=3";
            desc = "Create files/dirs (brace expansion; trailing / = dir)";
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
            run = "cd ~/${myconfig.constants.flakeDir}";
            desc = "Go ~/${myconfig.constants.flakeDir}";
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
            run = "cd ~/${myconfig.constants.flakeDir}/templates/krit/dev-environments";
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
            run = if isDarwin then "plugin trash" else "cd ~/.local/share/Trash/files";
            desc = "Go to Trash";
          }
          {
            on = [
              "g"
              "m"
            ];
            run = if isDarwin then "cd /Volumes" else "cd /mnt";
            desc = "Go to the mountpoints";
          }
          {
            on = [
              "g"
              "M"
            ];
            run = "cd ~/momentary";
            desc = "Go to the momentary";
          }
          {
            on = [
              "t"
              "c"
            ];
            run = "tab_create --current";
            desc = "Create a new tab with CWD";
          }
          {
            on = [
              "t"
              "d"
            ];
            run = "tab_close";
            desc = "Close the current tab";
          }
        ]
          ++ tabSwitch
          ++ [
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
            on = [ "k" ];
            run = "arrow -1";
            desc = "Previous task";
          }
          {
            on = [ "j" ];
            run = "arrow 1";
            desc = "Next task";
          }
        ];

        input.prepend_keymap = [
          {
            on = [ "<Backspace>" ];
            run = "backspace";
            desc = "Delete character";
          }
        ];
      };
    };
}
