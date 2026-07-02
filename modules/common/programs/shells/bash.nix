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
          if command -v tmux > /dev/null && [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
            tmux new-session -A -s main
          fi

          # 5. UWSM STARTUP (Universal & Safe)
          if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
              if command -v uwsm > /dev/null && uwsm check may-start > /dev/null && uwsm select; then
                  exec systemd-cat -t uwsm_start uwsm start default
              fi
          fi

        '';
      };
    };
}
