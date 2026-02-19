{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.walker.homeManagerModules.default ];

  home.packages = lib.mkIf config.programs.walker.enable (
    with pkgs;
    [
      xdg-utils
    ]
  );

  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      theme = "default";
      force_keyboard_focus = true;
      close_when_open = true;

      keybinds = {
        close = [ "Escape" ];
        page_down = [
          "ctrl d"
          "Page_Down"
        ];
        page_up = [
          "ctrl u"
          "Page_Up"
        ];
        resume_last_query = [ "ctrl r" ];
        accept_type = [ "ctrl ;" ];
      };

      builtins.emojis = {
        enable = true;
        name = "emojis";
        icon = "face-smile";
        placeholder = "Emojis";
        switcher_only = true;
        history = true;
        typeahead = false;
        exec = "wl-copy";
        show_unqualified = true;
        prefix = ".";
      };

      ui = {
        fullscreen = true;
        width = 1600;
        height = 1200;
        anchors = {
          top = true;
          bottom = true;
          left = true;
          right = true;
        };
      };

      list.max_results = 50;
      providers = {
        clipboard.max_results = 50;
        websearch.prefix = "@";
        finder.prefix = "/";
        commands.prefix = ":";
      };
    };

    themes.default = {
      style = with config.lib.stylix.colors.withHashtag; ''
        /* DYNAMIC BASE16 MAPPING */
        @define-color window_bg_color ${base00};
        @define-color accent_bg_color ${base0D};
        @define-color theme_fg_color  ${base05};
        @define-color error_bg_color  ${base08};
        @define-color error_fg_color  ${base00};

        * {
          all: unset;
          font-family: 'JetBrainsMono Nerd Font', monospace;
        }

        popover {
          background: lighter(@window_bg_color);
          border: 1px solid darker(@accent_bg_color);
          border-radius: 18px;
          padding: 10px;
        }

        .normal-icons {
          -gtk-icon-size: 16px;
        }

        .large-icons {
          -gtk-icon-size: 32px;
        }

        scrollbar {
          opacity: 0;
        }

        .box-wrapper {
          box-shadow:
            0 19px 38px rgba(0, 0, 0, 0.3),
            0 15px 12px rgba(0, 0, 0, 0.22);
          background: @window_bg_color;
          padding: 20px;
          border-radius: 20px;
          border: 1px solid darker(@accent_bg_color);
        }

        .preview-box,
        .elephant-hint,
        .placeholder {
          color: @theme_fg_color;
        }

        .box {
        }

        .search-container {
          border-radius: 10px;
        }

        .input placeholder {
          opacity: 0.5;
        }

        .input selection {
          background: lighter(lighter(lighter(@window_bg_color)));
        }

        .input {
          caret-color: @theme_fg_color;
          background: lighter(@window_bg_color);
          padding: 10px;
          color: @theme_fg_color;
        }

        .input:focus,
        .input:active {
        }

        .content-container {
        }

        .placeholder {
        }

        .scroll {
        }

        .list {
          color: @theme_fg_color;
        }

        child {
        }

        .item-box {
          border-radius: 10px;
          padding: 10px;
        }

        .item-quick-activation {
          background: alpha(@accent_bg_color, 0.25);
          border-radius: 5px;
          padding: 10px;
        }

        /* child:hover .item-box, */
        child:selected .item-box {
          background: alpha(@accent_bg_color, 0.25);
        }

        .item-text-box {
        }

        .item-subtext {
          font-size: 12px;
          opacity: 0.5;
        }

        .providerlist .item-subtext {
          font-size: unset;
          opacity: 0.75;
        }

        .item-image-text {
          font-size: 28px;
        }

        .preview {
          border: 1px solid alpha(@accent_bg_color, 0.25);
          /* padding: 10px; */
          border-radius: 10px;
          color: @theme_fg_color;
        }

        #clipboard label,
        #clipboard textview,
        #clipboard #text {
          background-color: lighter(@window_bg_color);
          color: @theme_fg_color;
          margin: 10px;
          padding: 10px;
          border-radius: 10px;
        }

        .calc .item-text {
          font-size: 24px;
        }

        .calc .item-subtext {
        }

        .symbols .item-image {
          font-size: 24px;
        }

        .todo.done .item-text-box {
          opacity: 0.25;
        }

        .todo.urgent {
          font-size: 24px;
        }

        .todo.active {
          font-weight: bold;
        }

        .bluetooth.disconnected {
          opacity: 0.5;
        }

        .preview .large-icons {
          -gtk-icon-size: 64px;
        }

        .keybinds {
          padding-top: 10px;
          border-top: 1px solid lighter(@window_bg_color);
          font-size: 12px;
          color: @theme_fg_color;
        }

        .global-keybinds {
        }

        .item-keybinds {
        }

        .keybind {
        }

        .keybind-button {
          opacity: 0.5;
        }

        .keybind-button:hover {
          opacity: 0.75;
          cursor: pointer;
        }

        .keybind-bind {
          text-transform: lowercase;
          opacity: 0.35;
        }

        .keybind-label {
          padding: 2px 4px;
          border-radius: 4px;
          border: 1px solid @theme_fg_color;
        }

        .error {
          padding: 10px;
          background: @error_bg_color;
          color: @error_fg_color;
        }

        :not(.calc).current {
          font-style: italic;
        }

        .preview-content.archlinuxpkgs {
          font-family: monospace;
        }
      '';
    };
  };
}
