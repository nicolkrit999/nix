{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "programs.tmux";
  options.programs.tmux = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    {
      constants,
      ...
    }:
    {
      # -----------------------------------------------------------------------
      # 🎨 CATPPUCCIN THEME
      # -----------------------------------------------------------------------
      catppuccin.tmux.enable = constants.catppuccin or false;
      catppuccin.tmux.flavor = constants.catppuccinFlavor or "mocha";

      catppuccin.tmux.extraConfig = lib.mkIf constants.catppuccin ''
        set -g @catppuccin_window_status_style "rounded"
        set -g @catppuccin_status_modules_right "directory session user host"
        set -g @catppuccin_window_current_fill "${constants.catppuccinAccent}"
      '';

      programs.tmux = {
        enable = true;
        baseIndex = 1;
        mouse = true;
        escapeTime = 0;
        keyMode = "vi";
        terminal = "screen-256color";

        extraConfig = ''
          # YAZI IMAGE PREVIEW SUPPORT
          set -g allow-passthrough on
          set -ga update-environment TERM
          set -ga update-environment TERM_PROGRAM

          # Enable RGB colors in terminal emulators that support it
          set -as terminal-features ",alacritty*:RGB"
          set -as terminal-features ",xterm-kitty:RGB"
          set -as terminal-features ",xterm-256color:RGB"

          bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"

          # --- CUSTOM BINDINGS (Alt/Meta based) ---
          bind -n M-r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
          bind C-p previous-window 
          bind C-n next-window

          # Window Navigation
          bind -n M-1 select-window -t 1
          bind -n M-2 select-window -t 2
          bind -n M-3 select-window -t 3
          bind -n M-4 select-window -t 4
          bind -n M-5 select-window -t 5
          bind -n M-6 select-window -t 6
          bind -n M-7 select-window -t 7
          bind -n M-8 select-window -t 8
          bind -n M-9 select-window -t 9

          # Pane Navigation
          bind -n M-Left select-pane -L
          bind -n M-Right select-pane -R
          bind -n M-Up select-pane -U
          bind -n M-Down select-pane -D

          # Resizing Panes
          bind -n M-S-Left resize-pane -L 5
          bind -n M-S-Right resize-pane -R 5
          bind -n M-S-Up resize-pane -U 3
          bind -n M-S-Down resize-pane -D 3

          # Splitting
          bind -n M-v split-window -h -c "#{pane_current_path}"
          bind -n M-h split-window -v -c "#{pane_current_path}"

          # Sessions management
          bind -n M-d detach-client
          bind -n M-S command-prompt -p "New Session:" "new-session -A -s '%%'"

          # --- PRODUCTIVITY SHORTCUTS ---
          bind -n M-Enter new-window
          bind -n M-c kill-pane
          bind -n M-q kill-window
          bind -n M-Q kill-session
        '';
        plugins = with pkgs; [
          # plugins...
        ];
      };
    };
}
