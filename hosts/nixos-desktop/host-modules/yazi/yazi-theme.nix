{
  pkgs,
  config,
  base16Theme,
  ...
}:
let
  # Grab the colors from Stylix's generated scheme
  colors = config.lib.stylix.colors;
in
{
  programs.yazi.theme = {
    # -----------------------------------------------------------------------
    # 🎨 DYNAMIC THEME (Base16)
    # -----------------------------------------------------------------------

    manager = {
      cwd = {
        fg = "#${colors.base0C}";
      };
      hovered = {
        fg = "#${colors.base05}";
        bg = "#${colors.base02}";
      };
      preview_hovered = {
        underline = true;
      };
      find_keyword = {
        fg = "#${colors.base0B}";
        italic = true;
      };
      find_position = {
        fg = "#${colors.base05}";
        bg = "reset";
        italic = true;
      };
      marker_selected = {
        fg = "#${colors.base0B}";
        bg = "#${colors.base0B}";
      };
      marker_copied = {
        fg = "#${colors.base0A}";
        bg = "#${colors.base0A}";
      };
      marker_cut = {
        fg = "#${colors.base08}";
        bg = "#${colors.base08}";
      };
    };

    mode = {
      normal_main = {
        fg = "#${colors.base00}";
        bg = "#${colors.base0D}";
        bold = true;
      };
      normal_alt = {
        fg = "#${colors.base0D}";
        bg = "#${colors.base00}";
      };
      select_main = {
        fg = "#${colors.base00}";
        bg = "#${colors.base0C}";
        bold = true;
      };
      select_alt = {
        fg = "#${colors.base0C}";
        bg = "#${colors.base00}";
      };
      unset_main = {
        fg = "#${colors.base00}";
        bg = "#${colors.base0F}";
        bold = true;
      };
      unset_alt = {
        fg = "#${colors.base0F}";
        bg = "#${colors.base00}";
      };
    };

    status = {
      separator_open = "";
      separator_close = "";
      separator_style = {
        fg = "#${colors.base02}";
        bg = "#${colors.base02}";
      };

      mode_normal = {
        fg = "#${colors.base00}";
        bg = "#${colors.base0D}";
        bold = true;
      };
      mode_select = {
        fg = "#${colors.base00}";
        bg = "#${colors.base0C}";
        bold = true;
      };
      mode_unset = {
        fg = "#${colors.base00}";
        bg = "#${colors.base0F}";
        bold = true;
      };

      progress_label = {
        fg = "#${colors.base05}";
        bold = true;
      };
      progress_normal = {
        fg = "#${colors.base0D}";
        bg = "#${colors.base02}";
      };
      progress_error = {
        fg = "#${colors.base08}";
        bg = "#${colors.base02}";
      };
    };

    filetype = {
      rules = [
        {
          mime = "image/*";
          fg = "#${colors.base0C}";
        }
        {
          mime = "video/*";
          fg = "#${colors.base0E}";
        }
        {
          mime = "audio/*";
          fg = "#${colors.base0E}";
        }
        {
          mime = "application/zip";
          fg = "#${colors.base09}";
        }
        {
          mime = "application/gzip";
          fg = "#${colors.base09}";
        }
        {
          mime = "application/tar";
          fg = "#${colors.base09}";
        }
        {
          name = "*.nix";
          fg = "#${colors.base0D}";
        }
        {
          name = "*.md";
          fg = "#${colors.base0A}";
        }
        {
          name = "*";
          fg = "#${colors.base05}";
        }
        {
          name = "*/";
          fg = "#${colors.base0D}";
          bold = true;
        }
      ];
    };
  };
}
