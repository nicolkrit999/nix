{
  config,
  pkgs,
  nixImpure,
  ...
}:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    sessionVariables = {
    };

    # -----------------------------------------------------------------------
    # ⌨️ SHELL ALIASES (Managed by Nix)
    # -----------------------------------------------------------------------
    shellAliases =
      let
        flakeDir = "~/nixOS";

        switchCmd =
          if nixImpure then "sudo nixos-rebuild switch --flake . --impure" else "nh os switch ${flakeDir}";

        updateCmd =
          if nixImpure then
            "nix flake update && sudo nixos-rebuild switch --flake . --impure"
          else
            "nh os switch --update ${flakeDir}";

        updateBoot =
          if nixImpure then
            "sudo nixos-rebuild boot --flake . --impure"
          else
            "nh os boot --update ${flakeDir}";
      in
      {

        # Smart aliases based on nixImpure setting
        sw = "cd ${flakeDir} && ${switchCmd}";
        upd = "cd ${flakeDir} && ${updateCmd}";

        # Manual are kept for reference, but use the above aliases instead
        swpure = "cd ${flakeDir} && nh os switch ${flakeDir}";
        swimpure = "cd ${flakeDir} && sudo nixos-rebuild switch --flake . --impure";

        # Other nix-related aliases
        hms = "cd ${flakeDir} && home-manager switch --flake ${flakeDir}#$(hostname)";
        pkgs = "nvim ${flakeDir}/home-manager/home-packages.nix";

        fmt-dry = "cd ${flakeDir} && nix fmt -- --check"; # Check formatting without making changes (list files that need formatting)
        fmt = "cd ${flakeDir} &&  nix fmt -- **/*.nix"; # Format Nix files using nixfmt (a regular nix fmt hangs on zed theme)

        # Utilities
        npu = "read 'url?Enter URL: ' && nix-prefetch-url \"$url\"";
        r = "ranger";
        v = "nvim";
        se = "sudoedit";

        # Various
        reb-uefi = "systemctl reboot - -firmware-setup"; # Reboot into UEFI firmware settings
        swboot = "cd ${flakeDir} && ${updateBoot}"; # Rebuilt boot without crash current desktop environment
      };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";

    # -----------------------------------------------------
    # ⚙️ SHELL INITIALIZATION
    # -----------------------------------------------------
    initExtra = ''
      # 1. LOAD USER CONFIG (Stow Integration)
      if [ -f "$HOME/.zshrc_custom" ]; then
        source "$HOME/.zshrc_custom"
      fi

      # 2. TMUX AUTOSTART (Only in GUI)
      # Ensure we are in a GUI before starting tmux automatically
      if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
        tmux new-session
      fi

      # 3. UWSM STARTUP (Universal & Safe)
      # Guard: Only run if on physical TTY1 AND no graphical session is active.
      if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
          
          # Check if uwsm is installed and ready (Safe for KDE/GNOME-only builds)
          if command -v uwsm > /dev/null && uwsm check may-start > /dev/null && uwsm select; then
              exec systemd-cat -t uwsm_start uwsm start default
          fi
      fi
    '';
  };
}
