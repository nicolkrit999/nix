{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.walker.homeManagerModules.default ];

  home.packages = [ pkgs.xdg-utils ];

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
        typeahead = true;
        exec = "wl-copy";
        show_unqualified = false;
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
        * {
          font-family: 'JetBrainsMono Nerd Font', monospace;
          color: ${base05}; 
        }

        #window {
          background-color: ${base00};
        }

        #input {
          background-color: ${base01};
          color: ${base05};
          border-radius: 12px;
          padding: 12px;
          margin: 20px;
          border: 2px solid ${base0D};
        }

        #input.empty {
          color: ${base03};
        }

        #list {
          margin: 20px;
          background-color: transparent;
        }

        .item {
          padding: 10px;
          border-radius: 8px;
          color: ${base05};
        }

        .item.active {
          background-color: ${base02};
          color: ${base0D};
          border: 1px solid ${base0D};
        }

        .icon {
          margin-right: 12px;
        }

        #clipboard_image {
          border-radius: 12px;
          margin: 20px;
          border: 2px solid ${base02};
          background-color: ${base01};
        }

        trough {
          background-color: transparent;
        }
        slider {
          background-color: ${base03};
          border-radius: 10px;
        }
      '';
    };
  };
}
