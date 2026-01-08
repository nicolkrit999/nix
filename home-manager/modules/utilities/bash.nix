{
  config,
  pkgs,
  lib,
  vars,
  ...
}:

lib.mkIf ((vars.shell or "zsh") == "bash") {
  programs.bash = {
    enable = true;
    enableCompletion = true;

    # -----------------------------------------------------------------------
    # ⌨️ ALIASES
    # -----------------------------------------------------------------------
    shellAliases =
      let
        flakeDir = "~/nixOS";

        isImpure = vars.nixImpure or false;

        switchCmd =
          if isImpure then "sudo nixos-rebuild switch --flake . --impure" else "nh os switch ${flakeDir}";

        updateCmd =
          if isImpure then
            "nix flake update && sudo nixos-rebuild switch --flake . --impure"
          else
            "nh os switch --update ${flakeDir}";

        updateBoot =
          if isImpure then
            "sudo nixos-rebuild boot --flake . --impure"
          else
            "nh os boot --update ${flakeDir}";
      in
      {
        # Smart aliases based on nixImpure setting
        sw = "cd ${flakeDir} && ${switchCmd}";
        swoff = "cd ${flakeDir} && ${switchCmd} --offline";
        gsw = "cd ${flakeDir} && git add -A && ${switchCmd}";
        gswoff = "cd ${flakeDir} && git add -A && ${switchCmd} --offline";
        upd = "cd ${flakeDir} && ${updateCmd}";

        # Manual are kept for reference, but use the above aliases instead
        swpure = "cd ${flakeDir} && nh os switch ${flakeDir}";
        swimpure = "cd ${flakeDir} && sudo nixos-rebuild switch --flake . --impure";

        # System maintenance
        dedup = "nix store optimise";
        cleanup = "nh clean all";

        # Pkgs editing
        pkgs-home = "$EDITOR ${flakeDir}/home-manager/home-packages.nix"; # Edit home-manager packages list
        pkgs-host = "$EDITOR ${flakeDir}/hosts/${vars.hostname}/optional/host-packages/local-packages.nix"; # Edit host-specific packages list

        # Nix repo management
        fmt-dry = "cd ${flakeDir} && nix fmt -- --check"; # Check formatting without making changes (list files that need formatting)
        fmt = "cd ${flakeDir} &&  nix fmt -- **/*.nix"; # Format Nix files using nixfmt (a regular nix fmt hangs on zed theme)
        merge_dev-main = "cd ${flakeDir} && git stash && git checkout main && git pull origin main && git merge develop && git push; git checkout develop && git stash pop"; # Merge main with develop branch, push and return to develop branch
        merge_main-dev = "cd ${flakeDir} && git stash && git checkout develop && git pull origin develop && git merge main && git push; git checkout develop && git stash pop"; # Merge develop with main branch, push and return to develop branch
        cdnix = "cd ${flakeDir}";

        # Snapshots
        snap-list-home = "snapper -c home list"; # List home snapshots
        snap-list-root = "sudo snapper -c root list"; # List root snapshots

        # Utilities
        se = "sudoedit";

        # Sops secrets editing
        sops-main = "cd ${flakeDir} && $EDITOR .sops.yaml"; # Edit main sops config
        sops-common = "cd ${flakeDir} && sops common/secrets.yaml"; # Edit sops secrets file
        sops-host = "cd ${flakeDir} && sops hosts/${vars.hostname}/optional/host-sops-nix/secrets.yaml"; # Edit host-specific sops secrets file

        # Various
        reb-uefi = "systemctl reboot --firmware-setup"; # Reboot into UEFI firmware settings
        swboot = "cd ${flakeDir} && ${updateBoot}"; # Rebuilt boot without crash current desktop environment
      };

    # -----------------------------------------------------
    # ⚙️ INITIALIZATION
    # -----------------------------------------------------
    initExtra = ''
      # 1. FIX HYPRLAND SOCKET
      if [ -d "/run/user/$(id -u)/hypr" ]; then
        # Use find to locate the specific socket file and extract the signature
        SOCKET_FILE=$(find /run/user/$(id -u)/hypr/ -name ".socket.sock" -print -quit)
        if [ -n "$SOCKET_FILE" ]; then
          export HYPRLAND_INSTANCE_SIGNATURE=$(basename $(dirname "$SOCKET_FILE"))
        fi
      fi

      # 2. LOAD USER CONFIG
      if [ -f "$HOME/.bashrc_custom" ]; then
        source "$HOME/.bashrc_custom"
      fi

      # 3. TMUX AUTOSTART
      if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
        tmux new-session
      fi

      # 4. SNAPSHOT FUNCTIONS (Bash Syntax)
      snap-lock() {
        echo "Which config? (1=home, 2=root)"
        read -p "Selection: " k
        if [[ "$k" == "2" ]]; then CFG="root"; else CFG="home"; fi
        sudo snapper -c "$CFG" list
        echo ""
        read -p "Enter Snapshot ID to LOCK: " ID
        if [[ -n "$ID" ]]; then
           sudo snapper -c "$CFG" modify -c "" "$ID"
           echo "✅ Snapshot #$ID in '$CFG' is now LOCKED."
        fi
      }

      # 5. UWSM STARTUP (Universal & Safe)
      if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
          if command -v uwsm > /dev/null && uwsm check may-start > /dev/null && uwsm select; then
              exec systemd-cat -t uwsm_start uwsm start default
          fi
      fi

      # -----------------------------------------------------
      # 6 SNAPSHOT LOCK & UNLOCK
      # -----------------------------------------------------
      snap-unlock() {
        echo "Which config? (1=home, 2=root)"
        read -p "Selection: " k
        if [[ "$k" == "2" ]]; then CFG="root"; else CFG="home"; fi
        sudo snapper -c "$CFG" list
        echo ""
        read -p "Enter Snapshot ID to UNLOCK: " ID
        if [[ -n "$ID" ]]; then
           sudo snapper -c "$CFG" modify -c "timeline" "$ID"
           echo "✅ Snapshot #$ID in '$CFG' is now UNLOCKED."
        fi
      }

      _snap_create() {
        local config_name=$1
        read -p "📝 Enter snapshot description: " description
        if [ -z "$description" ]; then echo "❌ Description cannot be empty."; return 1; fi
        read -p "🔒 Lock this snapshot (keep forever)? [y/N]: " lock_ans
        local cleanup_flag="-c timeline"
        if [[ "$lock_ans" =~ ^[Yy]$ ]]; then
          cleanup_flag=""
        fi
        sudo snapper -c "$config_name" create --description "$description" $cleanup_flag
      }


      # -----------------------------------------------------
      # 7 📦 SMART NIX PREFETCH (npu)
      # -----------------------------------------------------
      npu() {
        if [ -z "$1" ]; then read -p "Enter URL: " url; else url="$1"; fi
        if [[ "$url" == *"github.com"* ]] || [[ "$url" == *"gitlab.com"* ]]; then
          nix-prefetch-url --unpack "$url"
        else
          nix-prefetch-url "$url"
        fi
      }
    '';
  };
}
