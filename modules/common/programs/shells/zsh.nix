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
            if command -v tmux > /dev/null && [[ -z "$TMUX" ]] && [[ "$-" == *i* ]]; then
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
            if command -v tmux > /dev/null && [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
              tmux new-session -A -s main
            fi

            # UWSM STARTUP (Universal & Safe)
            if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
                if command -v uwsm > /dev/null && uwsm check may-start > /dev/null && uwsm select; then
                    exec systemd-cat -t uwsm_start uwsm start default
                fi
            fi
          '';
      };
    };
}
