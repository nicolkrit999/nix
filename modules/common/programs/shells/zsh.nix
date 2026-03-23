{ delib
, lib
, moduleSystem
, ...
}:
delib.module {
  name = "programs.zsh";

  # Always enabled to ensure the fixes functions works
  home.always =
    { myconfig, ... }:
    let
      currentShell = myconfig.constants.shell or "bash";
      isNixOS = moduleSystem == "nixos";
      isDarwin = moduleSystem == "darwin";
    in
    lib.mkIf (currentShell == "zsh") {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        initContent =
          # Common init
          ''
            # LOAD USER CONFIG
            if [ -f "$HOME/.zshrc_custom" ]; then
              source "$HOME/.zshrc_custom"
            fi
          ''
          # Darwin-specific init
          + lib.optionalString isDarwin ''
            # TMUX AUTOSTART (always on Darwin)
            if [[ -z "$TMUX" ]] && [[ "$-" == *i* ]]; then
              exec tmux new-session -A -s main
            fi

            export CASE_SENSITIVE="true"
            export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

            if [ -z "$SSH_AUTH_SOCK" ]; then
              eval "$(ssh-agent -s)" >/dev/null
              if [ -f "$HOME/.ssh/id_ed25519" ]; then
                ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" >/dev/null 2>&1 || true
              fi
            fi

            if [ -f "$HOME/.iterm2_shell_integration.zsh" ]; then
              . "$HOME/.iterm2_shell_integration.zsh"
            fi
          ''
          # NixOS-specific init
          + lib.optionalString isNixOS ''
              # FIX HYPRLAND SOCKET (Dynamic Update)
              if [ -d "/run/user/$(id -u)/hypr" ];
              then
                socket_file=$(find /run/user/$(id -u)/hypr/ -name ".socket.sock" -print -quit)
                if [ -n "$socket_file" ];
                then
                  export HYPRLAND_INSTANCE_SIGNATURE=$(basename $(dirname "$socket_file"))
                fi
              fi

              # TMUX AUTOSTART (Only in GUI)
              if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
                tmux new-session -A -s main
              fi

              # UWSM STARTUP (Universal & Safe)
              if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
                  if command -v uwsm > /dev/null && uwsm check may-start > /dev/null && uwsm select; then
                      exec systemd-cat -t uwsm_start uwsm start default
                  fi
              fi

            # -----------------------------------------------------
            # 6 📦 SMART NIX PREFETCH (npu)
            # -----------------------------------------------------
            npu() {
              local url="$1"
              if [ -z "$url" ]; then
                read "url?🔗 Enter URL: "
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
          '' + lib.optionalString (myconfig.services.snapshots.enable or false) ''
            # SNAPSHOT LOCK & UNLOCK
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
          '';
      };
    };
}
