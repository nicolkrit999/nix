# Core evaluation helper for the wallpaper test suite.
#
# Provides:
#   evalScenario  scenarioDir nixosExtraDir  -> nixosConfigurations attrset
#   getConfig     scenarioDir nixosExtraDir  -> resolved NixOS config
#   getHm         config                     -> home-manager sub-config for "krit"
#
# Two nixos-extra variants are supported:
#   nixosExtraX86  - x86_64-linux platform stub
#   nixosExtraAarch64 - aarch64-linux platform stub
#
# Uses builtins.getFlake "path:/home/krit/nix" which works without --impure
# because the path: scheme is a proper flake URI.
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  lib = flake.inputs.nixpkgs.lib;
  denix = flake.inputs.denix;

  # Common module paths shared by all wallpaper test scenarios.
  commonPaths = [
    # home-manager integration
    (src + "/modules/common/toplevel/home-manager.nix")

    # Constants schema (declares myconfig.constants.* options including wallpapers)
    (src + "/modules/nixos/config/constants-nixos.nix")
    (src + "/modules/common/config/constants.nix")

    # Catppuccin: adds catppuccin.* home-manager options (needed by hyprland-main)
    (src + "/modules/common/themes/catppuccin.nix")

    # WM enable options (singleEnableOption)
    (src + "/modules/nixos/toplevel/hyprland.nix")
    (src + "/modules/nixos/toplevel/niri.nix")
    (src + "/modules/nixos/toplevel/mango.nix")
    (src + "/modules/nixos/toplevel/gnome.nix")
    (src + "/modules/nixos/toplevel/kde.nix")

    # Window manager main modules + binds
    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-main.nix")
    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-binds.nix")
    (src + "/modules/nixos/programs/de-wm/niri/niri-main.nix")
    (src + "/modules/nixos/programs/de-wm/niri/niri-binds.nix")
    (src + "/modules/nixos/programs/de-wm/mango/mango-main.nix")
    (src + "/modules/nixos/programs/de-wm/mango/mango-binds.nix")

    # Desktop environments (use wallpaperURL for their backgrounds)
    (src + "/modules/nixos/programs/de-wm/gnome/gnome-main.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-main.nix")

    # skwd-wall module (the enable option the WMs read via parent.skwdWall.enable)
    (src + "/modules/nixos/programs/skwd-wall.nix")

    # Custom shells (wallpaper ownership logic)
    (src + "/modules/nixos/programs/shells/caelestia-main.nix")
    (src + "/modules/nixos/programs/shells/noctalia-main.nix")

    # Waybars (needed so waybar.*.enable options exist - waybars default off)
    (src + "/modules/nixos/programs/waybar/hyprland/waybar-hyprland.nix")
    (src + "/modules/nixos/programs/waybar/niri/waybar-niri.nix")
    (src + "/modules/nixos/programs/waybar/mango/waybar-mango.nix")

    # swaync (needed so services.swaync.enable option exists)
    (src + "/modules/nixos/services/swaync.nix")
    (src + "/modules/nixos/services/hypr/hyprlock.nix")
  ];

  nixosExtraX86 = src + "/templates/tests/nixos/test-nixos-wallpapers/shared/nixos-extra-x86_64";
  nixosExtraAarch64 = src + "/templates/tests/nixos/test-nixos-wallpapers/shared/nixos-extra-aarch64";

  evalScenarioWith = extraPaths: scenarioDir: nixosExtraDir:
    denix.lib.configurations {
      moduleSystem = "nixos";
      homeManagerUser = "krit";
      extensions = with denix.lib.extensions; [
        args
        (base.withConfig {
          args.enable = true;
          rices.enable = false;
        })
      ];
      specialArgs = {
        inputs = flake.inputs;
        moduleSystem = "nixos";
      };
      paths = [ scenarioDir nixosExtraDir ] ++ commonPaths ++ extraPaths;
      exclude = [ ];
    };

  evalScenario = evalScenarioWith [ ];

  getConfigWith = extraPaths: scenarioDir: nixosExtraDir:
    let
      configs = evalScenarioWith extraPaths scenarioDir nixosExtraDir;
      names = builtins.attrNames configs;
    in
    configs.${builtins.head names}.config;

  getConfig = scenarioDir: nixosExtraDir:
    let
      configs = evalScenario scenarioDir nixosExtraDir;
      names = builtins.attrNames configs;
    in
    configs.${builtins.head names}.config;

  getHm = config: config.home-manager.users.krit;

  # Render a Hyprland lua-mode exec-once entry into a flat string.
  # The on.hyprland.start lua function is stored as a mkLuaInline; its .expr
  # contains hl.exec_cmd("...") calls for each startup command.
  getHyprExecLua = config:
    let hm = getHm config;
    in (builtins.elemAt hm.wayland.windowManager.hyprland.settings.on._args 1).expr;

  # True iff the hyprland exec lua string contains the given substring.
  hyprExecHas = substr: config:
    lib.hasInfix substr (getHyprExecLua config);

  # Rebuild the mango wallpaperd launcher from the same inputs the module uses.
  # mango 0.18 cuts config values at 255 chars, so the specs live inside this
  # script and exec_once only holds its store path.
  mangoLauncher = config:
    let
      pkgs = flake.inputs.nixpkgs.legacyPackages.${config.nixpkgs.hostPlatform.system};
      wp = import (src + "/modules/nixos/programs/de-wm/wallpaperd/mk-wallpaperd.nix") { inherit lib pkgs; } {
        wm = "mango";
        wallpapers = config.myconfig.constants.wallpapers;
      };
    in
    wp.launcher;

  mangoExecList = config:
    let s = (getHm config).wayland.windowManager.mango.settings;
    in (s.exec or [ ]) ++ (s.exec_once or [ ]);

  # Extract mango exec list as a flat space-joined string for substring search.
  # An entry equal to the launcher store path is expanded to the launcher text
  # (the store path hashes that text, so a match proves the wired script has the specs).
  getMangoExecStr = config:
    let
      launcher = mangoLauncher config;
      expand = e: if e == "${launcher}" then "${e} ${launcher.text}" else e;
    in
    lib.concatStringsSep " " (map expand (mangoExecList config));

  mangoExecHas = substr: config:
    lib.hasInfix substr (getMangoExecStr config);

  # Extract niri spawn-at-startup commands into a flat string for substring search.
  getNiriSpawnStr = config:
    let hm = getHm config;
    in lib.concatStringsSep " "
      (map (e: lib.concatStringsSep " " e.command)
        hm.programs.niri.settings.spawn-at-startup);

  niriSpawnHas = substr: config:
    lib.hasInfix substr (getNiriSpawnStr config);

  # Per-WM accessors: flat startup string and substring predicate.
  wmStr = {
    hyprland = getHyprExecLua;
    mango = getMangoExecStr;
    niri = getNiriSpawnStr;
  };
  wmHas = {
    hyprland = hyprExecHas;
    mango = mangoExecHas;
    niri = niriSpawnHas;
  };

  # Occurrences of `needle` in the WM's startup string.
  wmCount = wm: needle: config:
    builtins.length (lib.splitString needle (wmStr.${wm} config)) - 1;

  # Expand expectations into one check per WM (hyprland, mango, niri).
  # Each expectation: { label; s = substring | (wm: substring); want = bool; }
  perWm = helpers: config: expectations:
    (lib.optionalAttrs (builtins.any (e: e.wiring or false) expectations) {
      "mango: wallpaperd launcher store path is an exec_once entry" =
        helpers.isTrue (builtins.elem "${mangoLauncher config}" (mangoExecList config));
    })
    // lib.optionalAttrs (builtins.any (e: !e.want) expectations) (lib.genAttrs
      (map (wm: "${wm}: startup is non-empty (negative checks are not vacuous)") (builtins.attrNames wmHas))
      (n: helpers.isTrue (builtins.stringLength (wmStr.${lib.head (lib.splitString ":" n)} config) > 0)))
    // lib.listToAttrs (lib.concatMap
      (wm: map
        (e:
          let needle = if builtins.isFunction e.s then e.s wm else e.s; in
          {
            name = "${wm}: ${e.label}";
            value = (if e.want then helpers.isTrue else helpers.isFalse)
              (wmHas.${wm} needle config);
          })
        expectations)
      (builtins.attrNames wmHas));

  # GNOME background must be the still (basename of the shared fixture), never a gif/video store path.
  isStillUri = uri: lib.hasPrefix "file:///nix/store/" uri && lib.hasSuffix "chainsaw_makima.png" uri;

  # Reusable expectations for perWm.
  expect = {
    supervisor = { label = "runs its own <wm>-wallpaperd supervisor"; s = wm: "${wm}-wallpaperd"; want = true; wiring = true; };
    noSupervisor = { label = "has no wallpaperd supervisor"; s = "-wallpaperd"; want = false; };
    daemon = { label = "starts awww-daemon --no-cache (a still image is used)"; s = "awww-daemon --no-cache"; want = true; };
    noDaemon = { label = "does NOT start awww-daemon (no still image)"; s = "awww-daemon"; want = false; };
    noDirectAwww = { label = "has no direct awww img call (supervisor owns it)"; s = "awww img"; want = false; };
    noDirectMpv = { label = "has no direct mpvpaper call (supervisor owns it)"; s = "mpvpaper"; want = false; };
    spec = label: s: { label = "spec contains ${label}"; inherit s; want = true; };
    noSpec = label: s: { label = "spec has no ${label}"; inherit s; want = false; };
  };

  # Check whether a package name appears in home.packages.
  hmHasPkg = pkgName: config:
    let
      hm = getHm config;
      names = map (p: p.pname or p.name or "") hm.home.packages;
    in
    builtins.any (n: lib.hasInfix pkgName n) names;

  # Whether the skwd-deck systemd service (skwd-walld) is enabled at the
  # NixOS system level - set by `nixos.ifEnabled` in skwd-wall.nix.
  skwdDeckEnabled = config: config.services.skwd-deck.enable or false;

  # KDE's plasma-manager wallpaperCustomPlugin.plugin, or null when unset
  # (mkIf false leaves the option at its default/empty submodule).
  kdeWallpaperCustomPlugin = config:
    let hm = getHm config;
    in hm.programs.plasma.workspace.wallpaperCustomPlugin.plugin or null;

in
{
  inherit evalScenario evalScenarioWith getConfig getConfigWith getHm lib flake;
  inherit nixosExtraX86 nixosExtraAarch64;
  inherit getHyprExecLua hyprExecHas;
  inherit getMangoExecStr mangoExecHas mangoLauncher;
  inherit getNiriSpawnStr niriSpawnHas;
  inherit wmStr wmHas wmCount perWm expect isStillUri;
  inherit hmHasPkg;
  inherit skwdDeckEnabled kdeWallpaperCustomPlugin;
}
