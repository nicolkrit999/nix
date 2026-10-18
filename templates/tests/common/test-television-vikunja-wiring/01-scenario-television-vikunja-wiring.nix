let
  flakeRoot =
    let
      r = builtins.getEnv "FLAKE_ROOT";
    in
    if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  nc = builtins.unsafeDiscardStringContext;

  twin =
    on: extra:
    flake.nixosConfigurations.template-host-minimal.extendModules {
      modules = [
        (
          { lib, ... }:
          {
            myconfig.programs.television.enable = lib.mkForce on;
            myconfig.programs.vikunja-desktop.enable = lib.mkForce on;
          }
        )
        extra
      ];
    };

  view =
    sys:
    let
      c = sys.config;
      h = c.home-manager.users.${c.myconfig.constants.user};
    in
    {
      inherit h;
      pkgs = sys.pkgs;
      hasPkg = p: builtins.elem (nc p.drvPath) (map (x: nc (x.drvPath or "")) h.home.packages);
    };

  scheme = "x-scheme-handler/vikunja-desktop";
  ok = cond: msg: if cond then "ok" else "FAIL: ${msg}";

  tvChecks =
    v:
    let
      toml = builtins.fromTOML (v.h.xdg.configFile."television/config.toml".text or "");
      act = nc (v.h.home.activation.updateTelevisionChannels.data or "");
    in
    {
      "television on: package in home.packages" = ok (v.hasPkg v.pkgs.television) "pkgs.television missing";
      "television on: config.toml is generated" =
        ok (v.h.xdg.configFile ? "television/config.toml") "no xdg.configFile television/config.toml";
      "television on: config.toml parses with integer tick_rate" =
        ok (builtins.isInt (toml.tick_rate or null)) "tick_rate missing or not an integer";
      "television on: activation updates channels with the pinned package" =
        ok (lib.hasInfix "${nc v.pkgs.television.outPath}/bin/tv update-channels" act)
          "updateTelevisionChannels does not run tv update-channels from pkgs.television";
    };

  vkChecks =
    v:
    let
      d = v.h.xdg.desktopEntries.vikunja-desktop or { };
      bin = "${nc v.pkgs.vikunja-desktop.outPath}/bin/vikunja-desktop";
      handler = v.h.xdg.mimeApps.defaultApplications.${scheme} or null;
    in
    {
      "vikunja-desktop on: package in home.packages" =
        ok (v.hasPkg v.pkgs.vikunja-desktop) "pkgs.vikunja-desktop missing";
      "vikunja-desktop on: desktop entry execs the packaged binary" =
        ok (lib.hasPrefix "${bin} " (nc (d.exec or ""))) "exec is '${nc (d.exec or "")}', not the package binary";
      "vikunja-desktop on: desktop entry advertises the OAuth scheme" =
        ok (builtins.elem scheme (d.mimeType or [ ])) "mimeType lacks ${scheme}";
      "vikunja-desktop on: default handler is the generated desktop entry" =
        ok (lib.toList handler == [ "vikunja-desktop.desktop" ]) "mimeApps default for ${scheme} is ${builtins.toJSON handler}";
    };

  on = view (twin true { });
  off = view (twin false { });

  offCheck = {
    "television off: no package, config or activation entry" =
      ok
        (
          !(off.hasPkg off.pkgs.television)
          && !(off.h.xdg.configFile ? "television/config.toml")
          && !(off.h.home.activation ? updateTelevisionChannels)
        )
        "television wiring leaked into the disabled twin";
    "vikunja-desktop off: no package, desktop entry or handler" =
      ok
        (
          !(off.hasPkg off.pkgs.vikunja-desktop)
          && !(off.h.xdg.desktopEntries ? vikunja-desktop)
          && !(off.h.xdg.mimeApps.defaultApplications ? ${scheme})
        )
        "vikunja-desktop wiring leaked into the disabled twin";
  };

  lines = attrs: lib.concatMapStrings (n: "${n}\t${attrs.${n}}\n") (builtins.attrNames attrs);

  broken = view (
    twin true (
      { lib, ... }:
      {
        home-manager.users.${flake.nixosConfigurations.template-host-minimal.config.myconfig.constants.user} = {
          xdg.configFile."television/config.toml".text = lib.mkForce "# no keys\n";
          home.activation.updateTelevisionChannels = lib.mkForce {
            before = [ ];
            after = [ ];
            data = "true";
          };
          xdg.desktopEntries.vikunja-desktop.exec = lib.mkForce "/bin/false %u";
          xdg.desktopEntries.vikunja-desktop.mimeType = lib.mkForce [ ];
          xdg.mimeApps.defaultApplications.${scheme} = lib.mkForce [ "other.desktop" ];
        };
      }
    )
  );
  brokenChecks = tvChecks broken // vkChecks broken;
  mustFail = [
    "television on: config.toml parses with integer tick_rate"
    "television on: activation updates channels with the pinned package"
    "vikunja-desktop on: desktop entry execs the packaged binary"
    "vikunja-desktop on: desktop entry advertises the OAuth scheme"
    "vikunja-desktop on: default handler is the generated desktop entry"
  ];
in
{
  rows = lines (tvChecks on // vkChecks on // offCheck);
  control = lib.concatMapStrings (
    n:
    "control: broken twin is rejected by '${n}'\t${
      if lib.hasPrefix "FAIL" brokenChecks.${n} then "ok" else "FAIL: check passed on a broken twin"
    }\n"
  ) mustFail;
}
