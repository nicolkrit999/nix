{ delib, inputs, pkgs, lib, moduleSystem, ... }:
let
  herdrPkgs = inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system} or { };
  # TEMPORARY: cargo-setup-hook forces ZSTD_SYS_USE_PKG_CONFIG=1 (herdr-app zstd-sys); remove when herdr-nix herdr-app.nix lists zstd.
  withZstd = drv:
    if lib.any (p: (p.pname or "") == "zstd") (drv.buildInputs or [ ]) then drv
    else
      drv.overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.zstd ];
      });
  fixed = herdrPkgs // lib.optionalAttrs (herdrPkgs ? herdr) { herdr = withZstd herdrPkgs.herdr; };
  herdrPackages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform)
    (lib.attrVals (lib.filter (n: fixed ? ${n}) [ "herdr" "herdr-core" "herdr-tui" ]) fixed);
  shared = {
    environment.systemPackages = herdrPackages;
  };
in
delib.module {
  name = "programs.herdr";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = shared;
  darwin.ifEnabled = shared;

  home.ifEnabled = {
    home.packages = lib.optionals (moduleSystem == "home") herdrPackages;

    # Declarative config.toml (read-only: herdr's settings UI cannot write it, edit here instead).
    # Keybinds mirror the Alt-based tmux ones in shells/tmux.nix; tmux windows = herdr tabs,
    # tmux sessions = herdr workspaces. tmux `split -v` stacks panes = herdr split_horizontal.
    xdg.configFile."herdr/config.toml" = {
      force = true;
      source = (pkgs.formats.toml { }).generate "herdr-config.toml" {
        onboarding = false;
        ui = {
          agent_panel_sort = "priority";
          status_indicators = "symbols";
          show_agent_labels_on_pane_borders = true;
          toast.delivery = "herdr";
        };
        theme = {
          name = "gruvbox";
          auto_switch = false;
        };
        keys = {
          reload_config = "alt+r";
          switch_tab = "alt+1..9";
          focus_pane_left = "alt+left";
          focus_pane_right = "alt+right";
          focus_pane_up = "alt+up";
          focus_pane_down = "alt+down";
          resize_pane_left = "alt+shift+left";
          resize_pane_right = "alt+shift+right";
          resize_pane_up = "alt+shift+up";
          resize_pane_down = "alt+shift+down";
          split_horizontal = "alt+v";
          split_vertical = "alt+h";
          detach = "alt+d";
          new_workspace = "alt+shift+s";
          new_tab = "alt+enter";
          close_pane = "alt+c";
          close_tab = "alt+q";
          close_workspace = "alt+shift+q";
        };
      };
    };
  };
}
