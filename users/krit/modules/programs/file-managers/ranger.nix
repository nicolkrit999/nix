{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "krit.programs.ranger";
  options.krit.programs.ranger = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    {
      myconfig,
      ...
    }:
    {
      home.packages =
        with pkgs;
        with pkgs;
        [
          ffmpegthumbnailer
          fzf
          ueberzugpp
        ];

      programs.ranger = {
        enable = false;
        rifle = [
          {
            condition = "flag f";
            command = ''xdg-open "$1"'';
          }
          {
            # Catch-all for everything else.
            condition = "else";
            command = ''xdg-open "$1"'';
          }
        ];

        mappings = {
          e = "edit";

          ec = "compress"; # Archive selected files using ranger-archives
          ex = "extract"; # Extract selected archive using ranger-archives

          b = "fzm"; # Fast directory jumping using fzf-marks
          "." = "set show_hidden!"; # Toggle hidden files on/off by pressing "."
        };

        # -----------------------------------------------------
        # ⚙️ PROGRAM SETTINGS
        # -----------------------------------------------------
        settings = {
          preview_images = true; # Enable image previews in terminal
          preview_images_method =
            if
              builtins.elem myconfig.constants.terminal [
                "kitty"
                "ghostty"
                "konsole"
                "wezterm"
                "rio"
                "iterm2"
              ]
            then
              "kitty"
            else if
              builtins.elem myconfig.constants.terminal [
                "foot"
                "blackbox"
              ]
            then
              "sixel"
            else
              "ueberzug"; # Use kitty or ueberzug for image previews
          wrap_scroll = true; # Enable smooth scrolling
          draw_borders = true; # Draws borders between columns
          w3m_delay = 0; # Instant rendering for w3m previews
        };

        # -----------------------------------------------------
        # 🎨 THEMING & ICONS
        # -----------------------------------------------------
        extraConfig = ''
          # Enables devicons2 to show Nerd Font icons next to filenames
          default_linemode devicons2
        '';

        # -----------------------------------------------------
        # 🧩 PLUGINS
        # -----------------------------------------------------
        plugins = [
          # Standard archive management (zip/tar/7z)
          {
            name = "ranger-archives";
            src = builtins.fetchGit {
              url = "https://github.com/maximtrp/ranger-archives";
              ref = "master";
              rev = "b4e136b24fdca7670e0c6105fb496e5df356ef25";
            };
          }

          # Nerd Font icon integration
          {
            name = "ranger-devicons2";
            src = builtins.fetchGit {
              url = "https://github.com/cdump/ranger-devicons2";
              ref = "master";
              rev = "94bdcc19218681debb252475fd9d11cfd274d9b1";
            };
          }

          # Persistence for Tmux sessions
          {
            name = "ranger_tmux";
            src = builtins.fetchGit {
              url = "https://github.com/joouha/ranger_tmux";
              ref = "master";
              rev = "05ba5ddf2ce5659a90aa0ada70eb1078470d972a";
            };
          }
        ];
      };

      # Custom python command to enable udisk mounting support
      home.file.".config/ranger/commands.py".text = "from plugins.ranger_udisk_menu.mounter import mount";

      xdg.desktopEntries.ranger = lib.mkForce {
        name = "Ranger";
        genericName = "File Manager";
        exec = "${myconfig.constants.terminal} --class ranger -e ranger";
        terminal = false;
        categories = [
          "System"
          "FileTools"
          "FileManager"
        ];
        mimeType = [ "inode/directory" ];
      };
    };
}
