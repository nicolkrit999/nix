{
  config,
  lib,
  vars,
  ...
}:

lib.mkIf ((vars.shell or "zsh") == "fish") {
  programs.fish = {
    enable = true;

    # -----------------------------------------------------------------------
    # ⌨️ ABBREVIATIONS
    # -----------------------------------------------------------------------
    shellAbbrs =
      let
        flakeDir = "~/nixOS";
        isImpure = vars.nixImpure or false;

        # Base commands
        baseSwitchCmd =
          if isImpure then "sudo nixos-rebuild switch --flake . --impure" else "nh os switch ${flakeDir}";

        baseUpdateCmd =
          if isImpure then
            "nix flake update && sudo nixos-rebuild switch --flake . --impure"
          else
            "nh os switch --update ${flakeDir}";

        baseBootCmd =
          if isImpure then
            "sudo nixos-rebuild boot --flake . --impure"
          else
            "nh os boot --update ${flakeDir}";

        # This wrap recognize if the current host is the "builder", allowing uploads
        wrapCachix =
          cmd:
          if (vars.cachix.enable or false) && (vars.cachix.push or false) then
            "env CACHIX_AUTH_TOKEN=$(command cat /run/secrets/cachix-auth-token) cachix watch-exec ${vars.cachix.name} -- ${cmd}"
          else
            cmd;

        # wrappped commands
        switchCmd = wrapCachix baseSwitchCmd;
        updateCmd = wrapCachix baseUpdateCmd;
        updateBoot = wrapCachix baseBootCmd;
      in
      {
        # Smart aliases based on nixImpure setting
        sw = "cd ${flakeDir} && ${switchCmd}";
        swsrc = "cd ${flakeDir} && ${switchCmd} --option substitute false";
        tswsrc = "cd ${flakeDir} && time ${switchCmd} --option substitute false";
        swoff = "cd ${flakeDir} && ${baseSwitchCmd} --offline";
        gsw = "cd ${flakeDir} && git add -A && ${switchCmd}";
        gswoff = "cd ${flakeDir} && git add -A && ${baseSwitchCmd} --offline";
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
    interactiveShellInit = ''
      # 1. FIX HYPRLAND SOCKET
      set -l hypr_dir "/run/user/"(id -u)"/hypr"
      if test -d "$hypr_dir"
        # Find the folder containing the .socket.sock and extract its name
        set -l socket_path (find "$hypr_dir" -name ".socket.sock" -print -quit)
        if test -n "$socket_path"
          set -l real_sig (basename (dirname "$socket_path"))
          set -gx HYPRLAND_INSTANCE_SIGNATURE "$real_sig"
        end
      end

      # 2. LOAD USER CONFIG
      if test -f "$HOME/.custom.fish"
        source "$HOME/.custom.fish"
      end

      # 3. TMUX AUTOSTART
      if not set -q TMUX; and set -q DISPLAY
        tmux new-session -A -s main
      end

      # 4. Disable greeting
      set -U fish_greeting


      # 5. UWSM STARTUP
      if test (tty) = "/dev/tty1"
          and test -z "$DISPLAY"
          and test -z "$WAYLAND_DISPLAY"
          
          if command -v uwsm > /dev/null
              and uwsm check may-start > /dev/null
              and uwsm select
              
              exec systemd-cat -t uwsm_start uwsm start default
          end
      end

      # FZF Keybindings
      fzf_key_bindings

      # 2. Fix fish-specific globbing and binding conflicts
      # Also solve tmux alt c conflict
      bind --erase --all alt-c 
      bind ctrl-g fzf-cd-widget
    '';

    # -----------------------------------------------------
    # 📝 FUNCTIONS
    # -----------------------------------------------------
    functions = {
      snap-lock = ''
        echo "Which config? (1=home, 2=root)"
        read -P "Selection: " k
        if test "$k" = "2"
          set CFG root
        else
          set CFG home
        end
        sudo snapper -c "$CFG" list
        echo ""
        read -P "Enter Snapshot ID to LOCK: " ID
        if test -n "$ID"
           sudo snapper -c "$CFG" modify -c "" "$ID"
           echo "✅ Snapshot #$ID in '$CFG' is now LOCKED."
        end
      '';

      snap-unlock = ''
        echo "Which config? (1=home, 2=root)"
        read -P "Selection: " k
        if test "$k" = "2"
          set CFG root
        else
          set CFG home
        end
        sudo snapper -c "$CFG" list
        echo ""
        read -P "Enter Snapshot ID to UNLOCK: " ID
        if test -n "$ID"
           sudo snapper -c "$CFG" modify -c "timeline" "$ID"
           echo "✅ Snapshot #$ID in '$CFG' is now UNLOCKED."
        end
      '';

      _snap_create = ''
        set config_name $argv[1]
        read -P "📝 Enter snapshot description: " description
        if test -z "$description"
          echo "❌ Description cannot be empty."
          return 1
        end
        read -P "🔒 Lock this snapshot (keep forever)? [y/N]: " lock_ans
        set cleanup_flag "-c" "timeline"
        if string match -r -i "^[yY]$" "$lock_ans"
          set cleanup_flag
        end
        sudo snapper -c "$config_name" create --description "$description" $cleanup_flag
      '';

      npu = ''
        set url ""
        if test -n "$argv[1]"
            set url "$argv[1]"
        else
            read -P "🔗 Enter URL: " url
        end

        if test -z "$url"
            echo "❌ No URL provided."
            return 1
        end

        # 1. Handle GitHub Blobs (Convert to Raw)
        if string match -q "https://github.com/*/blob/*" -- "$url"
            set url (string replace "github.com" "raw.githubusercontent.com" "$url" | string replace "/blob/" "/")
            echo "🔄 Converted Github Blob to Raw"
        end

        set args

        # 2. Handle GitHub Archives (Commits, Releases, Branches)
        if string match -q "https://github.com/*" -- "$url"
            if string match -q "*/commit/*" -- "$url"
                set url (string replace "/commit/" "/archive/" "$url").tar.gz
                set args --unpack
                echo "📦 Detected Github Commit -> Downloading Archive"
            else if string match -q "*/releases/tag/*" -- "$url"
                set url (string replace "/releases/tag/" "/archive/refs/tags/" "$url").tar.gz
                set args --unpack
                echo "📦 Detected Github Release -> Downloading Archive"
            else if string match -q "*/tree/*" -- "$url"
                set url (string replace "/tree/" "/archive/refs/heads/" "$url").tar.gz
                set args --unpack
                echo "📦 Detected Github Branch -> Downloading Archive"
            end
        end

        # 3. Handle Filename Decoding (Only if not unpacking)
        if test -z "$args"
            set filename (basename "$url")
            if command -q python3
                set decoded_name (python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$filename")
                if test "$filename" != "$decoded_name"
                    set args --name "$decoded_name"
                    echo "✨ Decoded filename: '$decoded_name'"
                end
            end
        end

        # Execute
        nix-prefetch-url $args "$url"
      '';
    };
  };
}
