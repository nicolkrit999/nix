let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  fx = import ../../lib/fixture-host.nix flake;
  sys = fx.mkNixos [{ myconfig.krit.programs.librewolf.enable = true; }];
  user = sys.config.myconfig.constants.user;
  lw = sys.config;
  hm = lw.home-manager.users.${user};
  profs = hm.programs.librewolf.profiles;
  userJs = n: hm.home.file."${hm.programs.librewolf.configPath}/${profs.${n}.path}/user.js".text;
  permsUrl = profs.privacy.settings."permissions.manager.defaultsUrl";
  overridesPaths = builtins.filter (lib.hasSuffix "/librewolf.overrides.cfg") (builtins.attrNames hm.home.file);
in
{
  pkg = hm.programs.librewolf.finalPackage;
  permsFile = sys.pkgs.runCommand "librewolf-privacy-permissions-copy" { } "cp ${lib.removePrefix "file://" permsUrl} $out";
  userJs = {
    default = userJs "default";
    privacy = userJs "privacy";
  };
  layout = {
    overrides = map (p: { path = p; text = hm.home.file.${p}.text; }) overridesPaths;
    profileDir = lib.mapAttrs (_: p: "${hm.programs.librewolf.configPath}/${p.path}") profs;
  };
}
