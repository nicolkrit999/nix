{
  config,
  pkgs,
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

        # Sops secrets editing
        sops-main = "cd ${flakeDir} && $EDITOR .sops.yaml"; # Edit main sops config
        sops-common = "cd ${flakeDir} && sops common/secrets.yaml"; # Edit sops secrets file
        sops-host = "cd ${flakeDir} && sops hosts/${vars.hostname}/optional/host-sops-nix/secrets.yaml"; # Edit host-specific sops secrets file

        # Various
        reb-uefi = "systemctl reboot --firmware-setup"; # Reboot into UEFI firmware settings
        updboot = "cd ${flakeDir} && ${updateBoot}"; # Rebuilt boot without crash current desktop environment
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
        if test -z "$argv[1]"
          read -P "Enter URL: " url
        else
          set url "$argv[1]"
        end
        if string match -q "*github.com*" "$url"; or string match -q "*gitlab.com*" "$url"
          nix-prefetch-url --unpack "$url"
        else
          nix-prefetch-url "$url"
        end
      '';
    };
  };
}
