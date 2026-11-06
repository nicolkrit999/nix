let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;
  shared = src + "/templates/tests/nixos/test-reboot-to-windows/shared";

  off = (denix.lib.configurations {
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
      inherit (flake) inputs;
      moduleSystem = "nixos";
    };
    paths = [
      (shared + "/host.nix")
      (shared + "/platform.nix")
      (shared + "/home-base.nix")
      (src + "/modules/nixos/toplevel/home-manager.nix")
      (src + "/modules/nixos/config/constants-nixos.nix")
      (src + "/modules/common/config/constants.nix")
      (src + "/modules/nixos/services/lanzaboote.nix")
    ];
    exclude = [ ];
  }).reboot-host;

  on = off.extendModules { modules = [{ myconfig.services.lanzaboote.enable = true; }]; };

  scripts = t: builtins.filter (p: (p.name or "") == "reboot-to-windows") t.config.environment.systemPackages;
  chk = cond: msg: if cond then "ok" else "FAIL: " + msg;
in
{
  checks = {
    "module off: reboot-to-windows is not installed" =
      chk (scripts off == [ ]) "found ${toString (builtins.length (scripts off))} package(s)";
    "module on: reboot-to-windows is installed exactly once" =
      chk (builtins.length (scripts on) == 1) "found ${toString (builtins.length (scripts on))} package(s)";
  };
  script = builtins.head (scripts on);
}
