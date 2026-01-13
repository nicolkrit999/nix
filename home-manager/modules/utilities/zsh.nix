{
  config,
  lib,
  vars,
  ...
}:

lib.mkIf ((vars.shell or "zsh") == "zsh") {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    sessionVariables = { };

    # -----------------------------------------------------------------------
    # ⌨️ SHELL ALIASES (Managed by Nix)
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
        gc = "nix-collect-garbage -d";

        # Home-Manager related (). Currently disabled because "sw" handle also home manager. Kept for reference
        # hms = "cd ${flakeDir} && home-manager switch --flake ${flakeDir}#${vars.hostname}"; # Rebuild home-manager config

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
        fzf-prev = "fzf --preview=\"cat {}\"";
        fzf-editor = "${vars.editor} \$(fzf -m --preview='cat {}')";
        zlist = "zoxide query -l -s"; # List all zoxide entries with scores

        # Sops secrets editing
        sops-main = "cd ${flakeDir} && $EDITOR .sops.yaml"; # Edit main sops config
        sops-common = "cd ${flakeDir} && sops common/${vars.user}-common-secrets-sops.yaml"; # Edit sops secrets file
        sops-host = "cd ${flakeDir} && sops hosts/${vars.hostname}/optional/host-sops-nix/${vars.hostname}-secrets-sops.yaml"; # Edit host-specific sops secrets file

        # Various
        reb-uefi = "systemctl reboot --firmware-setup"; # Reboot into UEFI firmware settings
        swboot = "cd ${flakeDir} && ${updateBoot}"; # Rebuilt boot without crash current desktop environment
      };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";

    # -----------------------------------------------------
    # ⚙️ SHELL INITIALIZATION
    # -----------------------------------------------------
    initExtra = ''
        # 1. FIX HYPRLAND SOCKET (Dynamic Update)
        if [ -d "/run/user/$(id -u)/hypr" ];
        then
          # Search for the actual socket file (Removed 'local' to fix error)
          socket_file=$(find /run/user/$(id -u)/hypr/ -name ".socket.sock" -print -quit)
          if [ -n "$socket_file" ];
          then
            export HYPRLAND_INSTANCE_SIGNATURE=$(basename $(dirname "$socket_file"))
          fi
        fi

        # 2. LOAD USER CONFIG
        if [ -f "$HOME/.zshrc_custom" ]; then
          source "$HOME/.zshrc_custom"
        fi

        # 3. TMUX AUTOSTART (Only in GUI)
        # Ensure we are in a GUI before starting tmux automatically
        if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
          tmux new-session -A -s main
        fi

        # 4. UWSM STARTUP (Universal & Safe)
        # Guard: Only run if on physical TTY1 AND no graphical session is active.
        if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
            
            # Check if uwsm is installed and ready (Safe for KDE/GNOME-only builds)
            if command -v uwsm > /dev/null && uwsm check may-start > /dev/null && uwsm select; then
                exec systemd-cat -t uwsm_start uwsm start default
            fi
        fi

        # -----------------------------------------------------
        # 5A SNAPSHOT LOCK & UNLOCK
        # -----------------------------------------------------
        # LOCK (Protect from auto-deletion)
        snap-lock() {
          echo "Which config? (1=home, 2=root)"
          read "k?Selection: "
          if [[ "$k" == "2" ]]; then CFG="root"; else CFG="home"; fi
          
          echo "Listing snapshots for $CFG..."
          sudo snapper -c "$CFG" list
          
          echo ""
          read "ID?Enter Snapshot ID to LOCK: "
          
          if [[ -n "$ID" ]]; then
             sudo snapper -c "$CFG" modify -c "" "$ID"
             echo "✅ Snapshot #$ID in '$CFG' is now LOCKED (won't be deleted)."
          fi
        }

        # UNLOCK (Allow auto-deletion)
        snap-unlock() {
          echo "Which config? (1=home, 2=root)"
          read "k?Selection: "
          if [[ "$k" == "2" ]]; then CFG="root"; else CFG="home"; fi
          
          echo "Listing snapshots for $CFG..."
          sudo snapper -c "$CFG" list
          
          echo ""
          read "ID?Enter Snapshot ID to UNLOCK: "
          
          if [[ -n "$ID" ]]; then
             sudo snapper -c "$CFG" modify -c "timeline" "$ID"
             echo "✅ Snapshot #$ID in '$CFG' is now UNLOCKED (timeline cleanup enabled)."
          fi
        }


      # -----------------------------------------------------------------------
      # 5B SNAPPER CREATE INTERACTIVE FUNCTION
      # -----------------------------------------------------------------------
      function _snap_create() {
        local config_name=$1
        
        echo -n "📝 Enter snapshot description: "
        read description
        
        if [ -z "$description" ]; then
          echo "❌ Description cannot be empty."
          return 1
        fi

        echo -n "🔒 Lock this snapshot (keep forever)? [y/N]: "
        read lock_ans

        local cleanup_flag="-c timeline"
        local lock_status="UNLOCKED (will auto-delete)"

        if [[ "$lock_ans" =~ ^[Yy]$ ]]; then
          cleanup_flag=""
          lock_status="LOCKED (safe forever)"
        fi

        echo "🚀 Creating $lock_status snapshot for '$config_name'..."
        sudo snapper -c "$config_name" create --description "$description" $cleanup_flag
      }

      alias snap-create-home="_snap_create home"
      alias snap-create-root="_snap_create root"

      # -----------------------------------------------------
      # 6 📦 SMART NIX PREFETCH (npu)
      # -----------------------------------------------------
      npu() {
        local url
        if [ -z "$1" ]; then
          read "url?Enter URL: "
        else
          url="$1"
        fi

        # Detect if the URL is a GitHub/GitLab repository archive
        if [[ "$url" == *"github.com"* ]] || [[ "$url" == *"gitlab.com"* ]]; then
          echo "📦 Git repository detected. Using --unpack for Nix compatibility..."
          nix-prefetch-url --unpack "$url"
        else
          echo "📄 Direct file detected. Fetching normally..."
          nix-prefetch-url "$url"
        fi
      }
    '';
  };
}
