{ delib
, ...
}:
delib.module {
  name = "programs.fish";

  # Always enabled to ensure the fixes functions works
  home.always =

    {
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
      '';

      functions = {
        fish_user_key_bindings = ''
          if functions -q fzf_key_bindings
            fzf_key_bindings
          end

          bind ctrl-g fzf-cd-widget

          bind --erase --all alt-c
        '';

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
