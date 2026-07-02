# Core evaluation helper for the wallpaper test suite.
#
# Provides:
#   evalScenario  scenarioDir nixosExtraDir  -> nixosConfigurations attrset
#   getConfig     scenarioDir nixosExtraDir  -> resolved NixOS config
#   getHm         config                     -> home-manager sub-config for "krit"
#
# Two nixos-extra variants are supported:
#   nixosExtraX86  — x86_64-linux platform stub
#   nixosExtraAarch64 — aarch64-linux platform stub
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

    # Waypaper module (the enable option the WMs read via parent.waypaper.enable)
    (src + "/modules/nixos/programs/waypaper.nix")

    # Custom shells (wallpaper ownership logic)
    (src + "/modules/nixos/programs/shells/caelestia-main.nix")
    (src + "/modules/nixos/programs/shells/noctalia-main.nix")

    # Waybars (needed so waybar.*.enable options exist — waybars default off)
    (src + "/modules/nixos/programs/waybar/hyprland/waybar-hyprland.nix")
    (src + "/modules/nixos/programs/waybar/niri/waybar-niri.nix")
    (src + "/modules/nixos/programs/waybar/mango/waybar-mango.nix")

    # swaync (needed so services.swaync.enable option exists)
    (src + "/modules/nixos/services/swaync.nix")
    (src + "/modules/nixos/services/hypr/hyprlock.nix")
  ];

  nixosExtraX86 = src + "/templates/tests/nixos/test-nixos-wallpapers/shared/nixos-extra-x86_64";
  nixosExtraAarch64 = src + "/templates/tests/nixos/test-nixos-wallpapers/shared/nixos-extra-aarch64";

  evalScenario = scenarioDir: nixosExtraDir:
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
      paths = [ scenarioDir nixosExtraDir ] ++ commonPaths;
      exclude = [ ];
    };

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

  # Extract mango exec list as a flat space-joined string for substring search.
  getMangoExecStr = config:
    let hm = getHm config;
    in lib.concatStringsSep " " hm.wayland.windowManager.mango.settings.exec;

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

  # Check whether a package name appears in home.packages.
  hmHasPkg = pkgName: config:
    let
      hm = getHm config;
      names = map (p: p.pname or p.name or "") hm.home.packages;
    in
    builtins.any (n: lib.hasInfix pkgName n) names;

in
{
  inherit evalScenario getConfig getHm lib flake;
  inherit nixosExtraX86 nixosExtraAarch64;
  inherit getHyprExecLua hyprExecHas;
  inherit getMangoExecStr mangoExecHas;
  inherit getNiriSpawnStr niriSpawnHas;
  inherit hmHasPkg;
}
