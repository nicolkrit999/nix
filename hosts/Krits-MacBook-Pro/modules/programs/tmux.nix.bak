{ delib, pkgs, lib, ... }:
delib.module {
  name = "programs.tmux";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    let
      isCatppuccin = myconfig.constants.theme.catppuccin or false;
      catppuccinFlavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccinAccent = myconfig.constants.theme.catppuccinAccent or "mauve";
    in
    {
      catppuccin.tmux.enable = isCatppuccin;
      catppuccin.tmux.flavor = catppuccinFlavor;

      catppuccin.tmux.extraConfig = lib.mkIf isCatppuccin ''
        set -g @catppuccin_window_status_style "rounded"
        set -g @catppuccin_status_modules_right "directory session user host"
        set -g @catppuccin_window_current_fill "${catppuccinAccent}"
      '';

      programs.tmux = {
        enable = true;
        baseIndex = 1;
        mouse = true;
        escapeTime = 0;
        keyMode = "vi";
        terminal = "screen-256color";

        extraConfig = ''
          set -g allow-passthrough on
          set -ga update-environment TERM
          set -ga update-environment TERM_PROGRAM

          set -as terminal-features ",alacritty*:RGB"
          set -as terminal-features ",xterm-kitty:RGB"
          set -as terminal-features ",xterm-256color:RGB"

          bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"

          bind -n M-R source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
          bind C-p previous-window
          bind C-n next-window

          bind -n M-1 select-window -t 1
          bind -n M-2 select-window -t 2
          bind -n M-3 select-window -t 3
          bind -n M-4 select-window -t 4
          bind -n M-5 select-window -t 5
          bind -n M-6 select-window -t 6
          bind -n M-7 select-window -t 7
          bind -n M-8 select-window -t 8
          bind -n M-9 select-window -t 9

          bind -n M-Left select-pane -L
          bind -n M-Right select-pane -R
          bind -n M-Up select-pane -U
          bind -n M-Down select-pane -D

          bind -n M-S-Left resize-pane -L 5
          bind -n M-S-Right resize-pane -R 5
          bind -n M-S-Up resize-pane -U 3
          bind -n M-S-Down resize-pane -D 3

          bind -n M-v split-window -h -c "#{pane_current_path}"
          bind -n M-h split-window -v -c "#{pane_current_path}"

          bind -n M-d detach-client
          bind -n M-S command-prompt -p "New Session Name:" "new-session -s '%%'"

          bind -n M-Enter new-window
          bind -n M-c kill-pane
          bind -n M-q kill-window
          bind -n M-Q kill-session
        '';
        plugins = with pkgs; [ ];
      };
    };
}
