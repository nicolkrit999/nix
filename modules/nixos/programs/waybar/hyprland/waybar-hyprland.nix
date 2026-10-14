{ delib
, lib
, config
, pkgs
, ...
}:
delib.module {
  name = "programs.waybar-hyprland";

  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      waybarLayout = attrsOption { };
      waybarWorkspaceIcons = attrsOption { };
      keyboardName = strOption "";
    };

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      # Hyprland 0.54+ rejects the built-in workspace click's old "dispatch workspace N" IPC.
      # Drop only after a waybar release containing PR #5013 AND a live workspace-click test.
      waybarPatched = pkgs.waybar.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./waybar-hyprland-lua-dispatch.patch ];
      });
      w = (import ../contrast-lib.nix { inherit lib; }).mkWaybar {
        inherit pkgs myconfig;
        colors = config.lib.stylix.colors.withHashtag;
      };

      isHyprlandEnabled = parent.hyprland.enable;
      caelestiaActiveOnHyprland = parent.caelestia.enable && parent.caelestia.enableOnHyprland;
      noctaliaActiveOnHyprland = parent.noctalia.enable && parent.noctalia.enableOnHyprland;
      hasShellOnHyprland = caelestiaActiveOnHyprland || noctaliaActiveOnHyprland;

      waybarConfig = w.bar // w.modules // {
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" "hyprland/window" ];
        modules-right = w.modulesRight "hyprland/language";

        "hyprland/workspaces" = {
          disable-scroll = true;
          show-special = true;
          all-outputs = false;
          format = "{id}{icon}";
          format-icons = cfg.waybarWorkspaceIcons // { default = ""; };
        };

        "hyprland/window" = {
          format = "{}";
          icon = false;
          max-length = 25;
          separate-outputs = true;
          rewrite = {
            "^$" = w.userHost;
          };
        };

        "hyprland/language" = {
          min-length = 5;
          tooltip = true;
        } // (
          if cfg.keyboardName != "" then {
            on-click = "hyprctl switchxkblayout ${cfg.keyboardName} next";
            keyboard-name = cfg.keyboardName;
          } else {
            on-click = "hyprctl switchxkblayout all next";
          }
        ) // cfg.waybarLayout;
      };
    in
    w.home
      {
        name = "hyprland";
        title = "Hyprland";
        enable = isHyprlandEnabled;
        target = "hyprland-session.target";
        config = waybarConfig;
        css = w.workspacesCss + builtins.readFile ./style.css;
        waybar = waybarPatched;
      } // {
      assertions = [
        {
          assertion = !(isHyprlandEnabled && hasShellOnHyprland);
          message = "waybar-hyprland is enabled together with an active shell (caelestia or noctalia) on Hyprland - disable one.";
        }
      ];
    };
}
