# Shared by 01-scenario-portal-routing.nix (real hosts, eval only) and 02-fake-case.nix.
#
# standIn: the portal data of a package that cache.nixos.org cannot serve, rebuilt without a
# compile. Each kind proves at eval time that its stand-in equals what the package installs.
{ lib, pkgs, flake }:
let
  stock = import flake.inputs.nixpkgs { inherit (pkgs.stdenv.hostPlatform) system; inherit (pkgs) config; };

  # Repo overlay that only appends a share/xdg-desktop-portal edit to postFixup
  # (xdg-portal.nix patchPortalPkg): stock output + the same edit.
  postFixupOnly = attr: p:
    let
      base = lib.getAttrFromPath attr stock;
      basePF = base.postFixup or "";
      suffix = lib.removePrefix basePF (p.postFixup or "");
      outRefs = lib.drop 1 (lib.splitString "$out" suffix);
      shareOnly = outRefs != [ ] && lib.all (lib.hasPrefix "/share/xdg-desktop-portal/") outRefs;
    in
    if p.outPath == base.outPath then null else
      assert lib.assertMsg ((p.overrideAttrs (_: { postFixup = base.postFixup or null; })).outPath == base.outPath)
        "stand-in ${p.name}: package differs from stock nixpkgs by more than postFixup";
      assert lib.assertMsg (lib.hasPrefix basePF (p.postFixup or "") && shareOnly)
        "stand-in ${p.name}: the extra postFixup does not only edit $out/share/xdg-desktop-portal";
      pkgs.runCommandLocal "${p.name}-portal-standin" { } ''
        mkdir -p $out/share
        cp -rL --no-preserve=mode ${base}/share/xdg-desktop-portal $out/share/
        ${suffix}
      '';

  # mango (flake input): meson install_data of the two asset files, no install hooks.
  mesonInstallData = files: p:
    let
      meson = builtins.readFile "${p.src}/meson.build";
      lines = [
        "desktop_install_dir = join_paths(prefix, 'share/wayland-sessions')"
        "portal_install_dir = join_paths(prefix, 'share/xdg-desktop-portal')"
      ] ++ map (f: "install_data('assets/${f.file}', install_dir : ${f.dir})") files;
      missing = lib.filter (l: !(lib.hasInfix l meson)) lines;
      hooks = lib.filter (h: lib.hasInfix "share" (p.${h} or "")) [ "postInstall" "postFixup" "preFixup" ];
    in
    assert lib.assertMsg (missing == [ ]) "stand-in ${p.name}: meson.build no longer has: ${lib.concatStringsSep "; " missing}";
    assert lib.assertMsg (hooks == [ ]) "stand-in ${p.name}: install hooks touch share/: ${toString hooks}";
    pkgs.runCommandLocal "${p.name}-portal-standin" { } (lib.concatMapStrings
      (f: ''
        install -Dm644 ${p.src}/assets/${f.file} $out/share/${if f.dir == "portal_install_dir" then "xdg-desktop-portal" else "wayland-sessions"}/${f.file}
      '')
      files);

  kinds = {
    xdg-desktop-portal-wlr = postFixupOnly [ "xdg-desktop-portal-wlr" ];
    mango = mesonInstallData [
      { file = "mango.desktop"; dir = "desktop_install_dir"; }
      { file = "mango-portals.conf"; dir = "portal_install_dir"; }
    ];
  };

  standIn = p: let n = lib.getName p; in if kinds ? ${n} then kinds.${n} p else null;

  entry = p: {
    name = lib.getName p;
    path = p.outPath;
    priority = p.meta.priority or 5;
    standIn = let s = standIn p; in if s == null then null else s.outPath;
    sessions = p.providedSessions or [ ];
  };
in
{
  inherit stock standIn entry;
  names = ps: lib.sort lib.lessThan (lib.unique (map lib.getName ps));
  # entry plus the derivation, fake host only: instantiating every real-host entry costs
  # minutes of eval and the real hosts are never built
  entryDrv = p: entry p // { drv = p.drvPath; };
}
