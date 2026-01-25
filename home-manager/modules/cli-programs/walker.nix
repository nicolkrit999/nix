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
        next = [
          "j"
          "Down"
        ];
        previous = [
          "k"
          "Up"
        ];
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

    theme = {
      style = with config.lib.stylix.colors.withHashtag; ''
        /* Global Reset */
        * {
          font-family: 'JetBrainsMono Nerd Font', monospace;
          color: ${base05}; 
        }

        /* Main Window */
        #window {
          background-color: ${base00};
        }

        /* Input Bar */
        #input {
          background-color: ${base01};
          color: ${base05};
          border-radius: 12px;
          padding: 12px;
          margin: 20px;
          border: 2px solid ${base0D};
        }

        /* Placeholder Text */
        #input.empty {
          color: ${base03};
        }

        /* The List */
        #list {
          margin: 20px;
          background-color: transparent;
        }

        /* Individual Items */
        .item {
          padding: 10px;
          border-radius: 8px;
          color: ${base05};
        }

        /* Selected Item */
        .item.active {
          background-color: ${base02};
          color: ${base0D};
          border: 1px solid ${base0D};
        }

        /* Icons */
        .icon {
          margin-right: 12px;
        }

        /* Clipboard Image Previews */
        #clipboard_image {
          border-radius: 12px;
          margin: 20px;
          border: 2px solid ${base02};
          background-color: ${base01};
        }

        /* Scrollbar */
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
