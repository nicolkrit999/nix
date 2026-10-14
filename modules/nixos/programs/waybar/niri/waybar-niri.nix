{ delib
, lib
, config
, pkgs
, ...
}:
delib.module {
  name = "programs.waybar-niri";

  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      waybarLayout = attrsOption { };
    };

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      w = (import ../contrast-lib.nix { inherit lib; }).mkWaybar {
        inherit pkgs myconfig;
        colors = config.lib.stylix.colors.withHashtag;
      };

      # Note: caelestia is hyprland-only, so not checked here.
      isNiriEnabled = parent.niri.enable;
      noctaliaActiveOnNiri = parent.noctalia.enable && parent.noctalia.enableOnNiri;

      waybarConfig = w.bar // w.modules // {
        modules-left = [ "niri/workspaces" ];
        modules-center = [ "clock" "custom/window" ];
        modules-right = w.modulesRight "niri/language";

        "niri/workspaces" = {
          format = "{index}";
          on-click = "activate";
        };

        "custom/window" = {
          exec = ''
            title=$({ niri msg -j workspaces; niri msg -j windows; } 2>/dev/null \
              | ${w.jq} -rs --arg out "$WAYBAR_OUTPUT_NAME" '
                  first(.[0][] | select(if $out == "" then .is_focused else .output == $out and .is_active end))
                    .active_window_id as $id
                  | .[1][] | select(.id == $id) | .title // empty | .[0:25] | @html' 2>/dev/null)
            if [ -z "$title" ]; then
              echo "${w.userHost}"
            else
              printf '%s' "$title"
            fi
          '';
          interval = 1;
          tooltip = false;
        };

        "niri/language" = {
          format = "{}";
          on-click = "niri msg action switch-layout-next";
        } // cfg.waybarLayout;
      };
    in
    w.home
      {
        name = "niri";
        title = "Niri";
        enable = isNiriEnabled;
        target = "niri.service";
        config = waybarConfig;
        css = w.workspacesCss + builtins.readFile ./style.css;
      } // {
      assertions = [
        {
          assertion = !(isNiriEnabled && noctaliaActiveOnNiri);
          message = "waybar-niri is enabled together with an active noctalia shell on Niri - disable one.";
        }
      ];
    };
}
