{ delib
, lib
, ...
}:
delib.module {
  name = "programs.bash";

  # Always enabled to ensure the fixes functions works
  home.always =
    { myconfig, ... }:
    let
      currentShell = myconfig.constants.shell or "bash";
    in
    lib.mkIf (currentShell == "bash") {
      programs.bash = {
        enable = true;
        initExtra = ''
          # 1. FIX HYPRLAND SOCKET
          if [ -d "/run/user/$(id -u)/hypr" ]; then
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
