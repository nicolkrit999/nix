{ delib
, lib
, ...
}:
delib.module {
  name = "programs.cosmic";

  home.ifEnabled =
    { cfg
    , ...
    }:
    let
      enum = variant: { __type = "enum"; inherit variant; };
      optional = value: { __type = "optional"; inherit value; };
      applet = id: "com.system76.${id}";

      autohideBehavior = {
        wait_time = 1000;
        transition_time = 200;
        handle_size = 4;
        unhide_delay = 200;
      };

      # Keys shared by both panels, restated because setting `panels` replaces the whole list.
      # `autohide` is left out on purpose: COSMIC 1.11 stores an enum there (Never / OnOverlap) but the
      # locked cosmic-manager only accepts the old Some(struct) shape, so it cannot be written.
      common = {
        anchor_gap = false;
        autohide_behavior = autohideBehavior;
        autohover_delay_ms = optional 500;
        background = enum "ThemeDefault";
        border_width = 0.0;
        keep_style_on_maximize = false;
        keyboard_interactivity = enum "OnDemand";
        layer = enum "Top";
        margin = 0;
        opacity = 1.0;
        output = enum "All";
        padding_overlap = 0.5;
        size_center = optional null;
        size_wings = optional null;
      };

      panel = common // {
        name = "Panel";
        anchor = enum "Top";
        border_radius = 0;
        exclusive_zone = true;
        expand_to_edges = true;
        padding = 0;
        size = enum "XS";
        spacing = 2;
        plugins_center = optional [ (applet "CosmicAppletTime") ];
        plugins_wings = optional {
          __type = "tuple";
          value = [
            [
              (applet "CosmicPanelWorkspacesButton")
              (applet "CosmicPanelAppButton")
            ]
            [
              (applet "CosmicAppletInputSources")
              (applet "CosmicAppletStatusArea")
              (applet "CosmicAppletA11y")
              (applet "CosmicAppletTiling")
              (applet "CosmicAppletAudio")
              (applet "CosmicAppletBluetooth")
              (applet "CosmicAppletNetwork")
              (applet "CosmicAppletBattery")
              (applet "CosmicAppletNotifications")
              (applet "CosmicAppletPower")
            ]
          ];
        };
      };

      dock = common // {
        name = "Dock";
        anchor = enum "Bottom";
        border_radius = 12;
        exclusive_zone = false;
        expand_to_edges = false;
        padding = 4;
        size = enum "L";
        spacing = 4;
        plugins_center = optional [
          (applet "CosmicPanelLauncherButton")
          (applet "CosmicPanelWorkspacesButton")
          (applet "CosmicPanelAppButton")
          (applet "CosmicAppList")
          (applet "CosmicAppletMinimize")
        ];
        plugins_wings = optional {
          __type = "tuple";
          value = [ [ ] [ ] ];
        };
      };

      favorites = lib.unique (lib.filter (id: id != "") (map (lib.removeSuffix ".desktop") cfg.pinnedApps));
    in
    {
      wayland.desktopManager.cosmic = {
        panels = [ panel dock ];
        applets.app-list.settings.favorites = lib.mkIf (favorites != [ ]) favorites;
      };
    };
}
