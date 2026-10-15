{ delib
, config
, lib
, ...
}:
delib.module {
  name = "krit.programs.yazi";

  home.ifEnabled =
    _:
    let
      colors = config.lib.stylix.colors;
    in
    {
      programs.yazi.theme = lib.mkForce {
        indicator = {
          parent = {
            fg = "#${colors.base05}";
            bg = "#${colors.base02}";
          };
          current = {
            fg = "#${colors.base05}";
            bg = "#${colors.base02}";
          };
          preview = {
            underline = true;
          };
        };

        mgr = {
          cwd = {
            fg = "#${colors.base0C}";
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
          sep_left = {
            open = "";
            close = "";
          };
          sep_right = {
            open = "";
            close = "";
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
              url = "*.nix";
              fg = "#${colors.base0D}";
            }
            {
              url = "*.md";
              fg = "#${colors.base0A}";
            }
            {
              url = "*";
              fg = "#${colors.base05}";
            }
            {
              url = "*/";
              fg = "#${colors.base0D}";
              bold = true;
            }
          ];
        };
      };
    };
}
