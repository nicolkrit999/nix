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
  # herdr-app (desktop app) default keys.json of this release, verbatim: the file is all-or-nothing
  # (an edited keys.json stops receiving new defaults), so the overrides go on top of it.
  appDefaultKeys = builtins.fromJSON ''
    {
      "global": {
        "alt-1": "space.select:1",
        "alt-2": "space.select:2",
        "alt-3": "space.select:3",
        "alt-4": "space.select:4",
        "alt-5": "space.select:5",
        "alt-6": "space.select:6",
        "alt-7": "space.select:7",
        "alt-8": "space.select:8",
        "alt-9": "space.select:9",
        "alt-h": "pane.go:left",
        "alt-j": "pane.go:down",
        "alt-k": "pane.go:up",
        "alt-l": "pane.go:right",
        "alt-left": "pane.go:left",
        "alt-right": "pane.go:right",
        "alt-shift-h": "pane.swap:left",
        "alt-shift-j": "pane.swap:down",
        "alt-shift-k": "pane.swap:up",
        "alt-shift-l": "pane.swap:right",
        "ctrl-+": "app.zoom_in",
        "ctrl--": "app.zoom_out",
        "ctrl-0": "app.zoom_reset",
        "ctrl-=": "app.zoom_in",
        "ctrl-1": "tab.select:1",
        "ctrl-2": "tab.select:2",
        "ctrl-3": "tab.select:3",
        "ctrl-4": "tab.select:4",
        "ctrl-5": "tab.select:5",
        "ctrl-6": "tab.select:6",
        "ctrl-7": "tab.select:7",
        "ctrl-8": "tab.select:8",
        "ctrl-9": "tab.select:9",
        "ctrl-pagedown": "tab.next",
        "ctrl-pageup": "tab.prev",
        "ctrl-tab": "tab.next",
        "ctrl-shift-tab": "tab.prev",
        "alt-]": "tab.next",
        "alt-[": "tab.prev",
        "ctrl-shift-pagedown": "space.next",
        "ctrl-shift-pageup": "space.prev",
        "alt-down": "agent.next",
        "alt-up": "agent.prev",
        "ctrl-?": "app.help",
        "ctrl-shift-/": "app.help",
        "ctrl-shift-?": "app.help",
        "ctrl-shift-b": "layout.toggle:sidebar",
        "ctrl-shift-n": "space.new",
        "ctrl-shift-t": "tab.new",
        "ctrl-shift-k": "mod.open:picker",
        "ctrl-shift-p": "app.palette",
        "ctrl-,": "app.settings",
        "ctrl-shift-o": "pane.split:right",
        "ctrl-shift-e": "pane.split:down",
        "ctrl-shift-w": "tab.close",
        "ctrl-shift-x": "pane.close",
        "ctrl-shift-z": "pane.zoom",
        "ctrl-shift-l": "layout.switch",
        "f2": "tab.rename",
        "shift-f2": "space.rename"
      },
      "terminal": {
        "ctrl-backspace": "send:\u0017",
        "ctrl-left": "send:\u001bb",
        "ctrl-right": "send:\u001bf",
        "ctrl-shift-c": "terminal.copy",
        "ctrl-shift-v": "terminal.paste",
        "ctrl-shift-f": "terminal.search",
        "ctrl-v": "terminal.paste_image",
        "ctrl-insert": "terminal.copy",
        "shift-insert": "terminal.paste"
      }
    }
  '';
  # Same keys as the Alt-based tmux binds in shells/tmux.nix (tmux window = herdr tab, tmux session = space,
  # tmux `split -v` stacks panes = pane.split:down). herdr-app has no resize or detach command.
  appKeys = lib.recursiveUpdate appDefaultKeys {
    global =
      lib.listToAttrs (map (n: lib.nameValuePair "alt-${toString n}" "tab.select:${toString n}") (lib.range 1 9))
      // {
        "alt-left" = "pane.go:left";
        "alt-right" = "pane.go:right";
        "alt-up" = "pane.go:up";
        "alt-down" = "pane.go:down";
        "alt-v" = "pane.split:down";
        "alt-h" = "pane.split:right";
        "alt-enter" = "tab.new";
        "alt-c" = "pane.close";
        "alt-q" = "tab.close";
        "alt-shift-q" = "space.close";
        "alt-shift-s" = "space.new";
      };
  };
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

    # Live-reloaded by the app; rejected keys are reported in ~/.config/herdr-app/keys.error.
    # Read-only: mods that merge their own keys into keys.json can't, add those keys above instead.
    xdg.configFile."herdr-app/keys.json" = {
      force = true;
      text = builtins.toJSON appKeys;
    };
  };
}
