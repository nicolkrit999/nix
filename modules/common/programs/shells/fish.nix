{ delib
, lib
, moduleSystem
, ...
}:
delib.module {
  name = "programs.fish";

  # Always enabled to ensure the fixes functions works
  home.always =
    { myconfig, ... }:
    let
      currentShell = myconfig.constants.shell or "bash";
      isNixOS = moduleSystem == "nixos";
      isDarwin = moduleSystem == "darwin";
    in
    lib.mkIf (currentShell == "fish") {
      programs.fish = {
        enable = true;

        interactiveShellInit =
          # Common init for both platforms
          ''
            # LOAD USER CONFIG
            if test -f "$HOME/.custom.fish"
              source "$HOME/.custom.fish"
            end

            # TMUX AUTOSTART (GUI only on NixOS, always on Darwin)
            ${if isDarwin then ''
              if command -v tmux > /dev/null
                and status is-interactive
                and not set -q TMUX
                exec tmux new-session -A -s main
              end
            '' else ''
              if command -v tmux > /dev/null; and not set -q TMUX; and set -q DISPLAY
                tmux new-session -A -s main
              end
            ''}

            # Disable greeting
            set -U fish_greeting

            # FZF keybindings
            bind --erase --all alt-c
            bind ctrl-g fzf-cd-widget
          ''
          # NixOS-specific init
          + lib.optionalString isNixOS ''
            # FIX HYPRLAND SOCKET
            set -l hypr_dir "/run/user/"(id -u)"/hypr"
            if test -d "$hypr_dir"
              set -l socket_path (find "$hypr_dir" -name ".socket.sock" -print -quit)
              if test -n "$socket_path"
                set -l real_sig (basename (dirname "$socket_path"))
                set -gx HYPRLAND_INSTANCE_SIGNATURE "$real_sig"
              end
            end

            # UWSM STARTUP
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
        };
      };
    };
}
