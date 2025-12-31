{
  config,
  pkgs,
  vars,
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
          if vars.nixImpure then
            "sudo nixos-rebuild switch --flake . --impure"
          else
            "nh os switch ${flakeDir}";

        updateCmd =
          if vars.nixImpure then
            "nix flake update && sudo nixos-rebuild switch --flake . --impure"
          else
            "nh os switch --update ${flakeDir}";

        updateBoot =
          if vars.nixImpure then
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

        # System maintenance
        dedup = "nix store optimise";
        cleanup = "nh clean all";

        # Home-Manager related
        hms = "cd ${flakeDir} && home-manager switch --flake ${flakeDir}#$(vars.hostname)"; # Rebuild home-manager config

        # Pkgs editing
        pkgs-home = "nvim ${flakeDir}/home-manager/home-packages.nix"; # Edit home-manager packages list
        pkgs-host = "nvim ${flakeDir}/hosts/${vars.hostname}/local-packages.nix"; # Edit host-specific packages list

        # Nix repo management
        fmt-dry = "cd ${flakeDir} && nix fmt -- --check"; # Check formatting without making changes (list files that need formatting)
        fmt = "cd ${flakeDir} &&  nix fmt -- **/*.nix"; # Format Nix files using nixfmt (a regular nix fmt hangs on zed theme)
        merge_dev-main = "cd ${flakeDir} && git stash && git checkout main && git pull origin main && git merge develop && git push; git checkout develop && git stash pop"; # Merge main with develop branch, push and return to develop branch
        merge_main-dev = "cd ${flakeDir} && git stash && git checkout develop && git pull origin develop && git merge main && git push; git checkout develop && git stash pop"; # Merge develop with main branch, push and return to develop branch

        # Utilities
        npu = "read 'url?Enter URL: ' && nix-prefetch-url \"$url\"";
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
      # 1. FIX HYPRLAND SOCKET (Dynamic Update)
      # This ensures that even inside tmux or after a crash, the shell finds the correct socket.
      if [ -d "/run/user/$(id -u)/hypr" ]; then
        export HYPRLAND_INSTANCE_SIGNATURE=$(ls -w 1 /run/user/$(id -u)/hypr/ | grep -v ".lock" | head -n 1)
      fi

      # 2. LOAD USER CONFIG (Stow Integration)
      if [ -f "$HOME/.zshrc_custom" ]; then
        source "$HOME/.zshrc_custom"
      fi

      # 3. TMUX AUTOSTART (Only in GUI)
      # Ensure we are in a GUI before starting tmux automatically
      if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
        tmux new-session
      fi

      # 4. UWSM STARTUP (Universal & Safe)
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
