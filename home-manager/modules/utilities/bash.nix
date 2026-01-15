{
  config,
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
        gc = "nix-collect-garbage -d";

        # Pkgs editing
        pkgs-home = "$EDITOR ${flakeDir}/home-manager/home-packages.nix"; # Edit home-manager packages list
        pkgs-host = "$EDITOR ${flakeDir}/hosts/${vars.hostname}/optional/host-packages/local-packages.nix"; # Edit host-specific packages list

        # Nix repo management
        fmt-dry = "cd ${flakeDir} && nix fmt -- --check"; # Check formatting without making changes (list files that need formatting)
        fmt = "cd ${flakeDir} &&  nix fmt -- **/*.nix"; # Format Nix files using nixfmt (a regular nix fmt hangs on zed theme)
        merge_dev-main = "cd ${flakeDir} && git stash && git checkout main && git pull origin main && git merge develop && git push; git checkout develop && git stash pop"; # Merge main with develop branch, push and return to develop branch
        merge_main-dev = "cd ${flakeDir} && git stash && git checkout develop && git pull origin develop && git merge main && git push; git checkout develop && git stash pop"; # Merge develop with main branch, push and return to develop branch
        cdnix = "cd ${flakeDir}";
        nfc = "cd ${flakeDir} && nix flake check"; # Check flake for errors
        swdry = "cd ${flakeDir} && nh os test --dry --ask"; # Dry run of nixos-rebuild switch

        # Snapshots
        snap-list-home = "snapper -c home list"; # List home snapshots
        snap-list-root = "sudo snapper -c root list"; # List root snapshots

        # Utilities
        se = "sudoedit";
        fzf-prev = ''fzf --preview="cat {}"'';
        fzf-editor = "${vars.editor} $(fzf -m --preview='cat {}')";
        zlist = "zoxide query -l -s"; # List all zoxide entries with scores

        # Sops secrets editing
        sops-main = "cd ${flakeDir} && $EDITOR .sops.yaml"; # Edit main sops config
        sops-common = "cd ${flakeDir} && sops common/${vars.user}-common-secrets-sops.yaml"; # Edit sops secrets file
        sops-host = "cd ${flakeDir} && sops hosts/${vars.hostname}/optional/host-sops-nix/${vars.hostname}-secrets-sops.yaml"; # Edit host-specific sops secrets file

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
        tmux new-session -A -s main
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
        local url="$1"
        if [ -z "$url" ]; then
          read -p "🔗 Enter URL: " url
        fi

        if [ -z "$url" ]; then echo "❌ No URL provided."; return 1; fi

        # 1. Handle GitHub Blobs
        if [[ "$url" == https://github.com/*/blob/* ]]; then
          url="''${url/github.com/raw.githubusercontent.com}"
          url="''${url/\/blob\//\/}"
          echo "🔄 Converted Github Blob to Raw"
        fi

        local args=""

        # 2. Handle GitHub Archives
        if [[ "$url" == https://github.com/* ]]; then
          if [[ "$url" == */commit/* ]]; then
            url="''${url/\/commit\//\/archive\/}.tar.gz"
            args="--unpack"
            echo "📦 Detected Github Commit -> Downloading Archive"
          elif [[ "$url" == */releases/tag/* ]]; then
            url="''${url/\/releases\/tag\//\/archive\/refs\/tags\/}.tar.gz"
            args="--unpack"
            echo "📦 Detected Github Release -> Downloading Archive"
          elif [[ "$url" == */tree/* ]]; then
            url="''${url/\/tree\//\/archive\/refs\/heads\/}.tar.gz"
            args="--unpack"
            echo "📦 Detected Github Branch -> Downloading Archive"
          fi
        fi

        # 3. Decode Filename
        if [ -z "$args" ]; then
          local filename=$(basename "$url")
          if command -v python3 >/dev/null 2>&1; then
            local decoded_name=$(python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$filename")
            if [ "$filename" != "$decoded_name" ]; then
              args="--name \"$decoded_name\""
              echo "✨ Decoded filename: '$decoded_name'"
            fi
          fi
        fi

        # Execute
        eval nix-prefetch-url $args "$url"
      }
    '';
  };
}
