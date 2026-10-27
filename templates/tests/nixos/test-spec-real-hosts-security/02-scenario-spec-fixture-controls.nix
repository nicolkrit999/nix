let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  fx = import ../../lib/fixture-host.nix flake;

  des = [ "hyprland" "niri" "mango" "gnome" "kde" "cosmic" ];
  excludedDirs = [ lingerDir "/var/lib/containers" "/var/lib/docker" "/var/lib/flatpak" "/var/lib/snapper" "/var/lib/tailscale" ];
  keptDir = "/var/lib/nixos";
  lingerDir = "/var/lib/systemd/linger";
  offUnits = [ "nh-clean" "snapperd" "snapper-timeline" "snapper-cleanup" "cleanup-trash" ];
  kritPaths = lib.filter (p: lib.hasAttrByPath ([ "myconfig" "krit" ] ++ p) sys.options) [
    [ "programs" "claude-code-wrappers" ]
    [ "services" "cloud" "googleDrive" ]
    [ "services" "cloud" "onedrivePersonal" ]
    [ "services" "cloud" "pcloud" ]
    [ "services" "cloud" "protonDrive" ]
    [ "services" "nas" "desktop-borg-backup" ]
    [ "services" "nas" "laptop-borg-backup" ]
    [ "services" "nas" "opencloud-mount" ]
    [ "services" "nas" "smb" ]
    [ "services" "nas" "sshfs" ]
    [ "services" "windows-mount" ]
  ];
  on = path: lib.setAttrByPath (path ++ [ "enable" ]) true;
  lsPort = 53317;

  mkFx = extra: fx.mkNixos ([
    {
      myconfig.specializations.guest.enable = true;
      myconfig.specializations.secure-travel.enable = true;
      nix.settings.allowed-users = [ "@wheel" ];
      users.users.root.hashedPassword = "fixture-unlocked";
      sops.secrets.github_fg_pat_token_nix.mode = "0444";
      environment.persistence."/persist".directories = excludedDirs ++ [ keptDir ];
      services.tailscale.openFirewall = true;
      networking.firewall.trustedInterfaces = [ "tailscale0" ];
      programs.nh.clean.enable = true;
    }
  ]
  ++ map (p: on ([ "myconfig" "krit" ] ++ p)) kritPaths
  ++ map (d: on [ "myconfig" "programs" d ]) des
  ++ map on [
    [ "myconfig" "programs" "openlogi" ]
    [ "myconfig" "programs" "thunderbird" ]
    [ "myconfig" "services" "tailscale" ]
    [ "myconfig" "services" "localsend" ]
    [ "myconfig" "services" "snapshots" ]
    [ "myconfig" "services" "autotrash" ]
    [ "services" "openssh" ]
    [ "services" "avahi" ]
    [ "virtualisation" "docker" ]
    [ "virtualisation" "podman" ]
  ]
  ++ extra);

  sys = fx.mkNixos [ ];
  b = (mkFx [ ]).config;
  g = b.specialisation.guest.configuration;
  s = b.specialisation.secure-travel.configuration;
  user = b.myconfig.constants.user;

  exposure = [
    (c: c.myconfig.services.tailscale.enable)
    (c: c.myconfig.services.localsend.enable)
    (c: c.services.openssh.enable)
    (c: c.services.avahi.enable)
    (c: c.virtualisation.docker.enable)
    (c: c.virtualisation.podman.enable)
  ];
  kritEnable = c: p: lib.attrByPath ([ "myconfig" "krit" ] ++ p ++ [ "enable" ]) false c;
  persistDirs = c: map (d: d.directory) c.environment.persistence."/persist".directories;
  hasUnit = c: n: c.systemd.services ? ${n} || c.systemd.timers ? ${n};
  pkgNames = pkgs: map (p: p.pname or p.name or "") pkgs;

  eq = what: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${what}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
  yes = what: cond: if cond then "ok" else "FAIL: ${what}";

  withLocalsend = on': (mkFx [{ myconfig.services.localsend.enable = lib.mkForce on'; }]).config;
  lsOn = withLocalsend true;
  lsOff = withLocalsend false;
  lsPkgIn = c: builtins.elem c.programs.localsend.package.pname (pkgNames c.environment.systemPackages);
  lsWired = c: c.programs.localsend.enable && builtins.elem lsPort c.networking.firewall.allowedTCPPorts
    && builtins.elem lsPort c.networking.firewall.allowedUDPPorts && lsPkgIn c;

  checks = {
    "control: base exposes every service the guest must turn off" = yes "base lacks some of tailscale/localsend/ssh/avahi/docker/podman" (builtins.all (f: f b) exposure);
    "guest: every exposure service the base turns on is off" = yes "still on in guest: ${toString (lib.imap0 (i: f: if f g then toString i else "") exposure)}" (!(builtins.any (f: f g) exposure));
    "control: base has openlogi and thunderbird on" = eq "base openlogi/thunderbird" [ b.myconfig.programs.openlogi.enable b.myconfig.programs.thunderbird.enable ] [ true true ];
    "guest: openlogi and thunderbird modules are off" = eq "guest openlogi/thunderbird" [ g.myconfig.programs.openlogi.enable g.myconfig.programs.thunderbird.enable ] [ false false ];
    "control: base has every DE enabled" = yes "base DE flags ${builtins.toJSON (map (d: b.myconfig.programs.${d}.enable) des)}" (builtins.all (d: b.myconfig.programs.${d}.enable) des);
    "guest: no DE of the base stays enabled" = yes "guest DE flags ${builtins.toJSON (map (d: g.myconfig.programs.${d}.enable) des)}" (!(builtins.any (d: g.myconfig.programs.${d}.enable) des));
    "control: base enables every krit nas/cloud/mount module" = yes "base lacks ${toString (map (lib.concatStringsSep ".") (lib.filter (p: !(kritEnable b p)) kritPaths))}" (kritPaths != [ ] && builtins.all (p: kritEnable b p) kritPaths);
    "guest: every krit nas/cloud/mount module is off" = yes "still on in guest: ${toString (map (lib.concatStringsSep ".") (lib.filter (p: kritEnable g p) kritPaths))}" (!(builtins.any (p: kritEnable g p) kritPaths));
    "control: base has the nh clean, snapper and autotrash units" = yes "base lacks ${toString (lib.filter (n: !(hasUnit b n)) offUnits)}" (builtins.all (hasUnit b) offUnits);
    "guest: nh clean, snapper and autotrash units are gone" = yes "guest still has ${toString (lib.filter (hasUnit g) offUnits)}" (!(builtins.any (hasUnit g) offUnits));
    "control: base persists linger, docker, containers, tailscale, flatpak and snapper" = yes "base persist list ${builtins.toJSON (persistDirs b)}" (builtins.all (d: builtins.elem d (persistDirs b)) excludedDirs);
    "guest: /persist drops the excluded directories and keeps the others" = eq "guest persist list" (persistDirs g) [ keptDir ];
    "control: base allowed-users differs from the guest" = yes "base allowed-users ${builtins.toJSON b.nix.settings.allowed-users}" (b.nix.settings.allowed-users != [ user ]);
    "guest: nix allowed-users is only the main user" = eq "allowed-users" g.nix.settings.allowed-users [ user ];
    "control: base PAT mode is world-readable" = eq "base PAT mode" b.sops.secrets.github_fg_pat_token_nix.mode "0444";
    "guest: PAT mode override wins over the base mode" = eq "guest PAT mode" g.sops.secrets.github_fg_pat_token_nix.mode "0400";
    "control: base root account is not locked" = yes "base root ${b.users.users.root.hashedPassword}" (b.users.users.root.hashedPassword != "!");
    "secure-travel: root account locked over an unlocked base" = eq "root pw" s.users.users.root.hashedPassword "!";
    "control: base opens the tailscale firewall and trusts tailscale0" = eq "base tailscale firewall" [ b.services.tailscale.openFirewall (builtins.elem "tailscale0" b.networking.firewall.trustedInterfaces) ] [ true true ];
    "secure-travel: tailscale firewall closed and tailscale0 not trusted" = eq "secure-travel firewall" [ s.services.tailscale.openFirewall (builtins.elem "tailscale0" s.networking.firewall.trustedInterfaces) ] [ false false ];
    "secure-travel: docker and localsend off while the base has them on" = eq "secure-travel docker/localsend" [ b.virtualisation.docker.enable s.virtualisation.docker.enable b.myconfig.services.localsend.enable s.myconfig.services.localsend.enable ] [ true false true false ];
    "secure-travel: gnome is the only DE while the base has all" = eq "secure-travel DE flags" (map (d: s.myconfig.programs.${d}.enable) des) (map (d: d == "gnome") des);
    "secure-travel: openssh and avahi off while the base has them on" = eq "secure-travel ssh/avahi" [ b.services.openssh.enable b.services.avahi.enable s.services.openssh.enable s.services.avahi.enable ] [ true true false false ];
    "localsend: enabled module sets programs.localsend.enable" = eq "programs.localsend" lsOn.programs.localsend.enable true;
    "localsend: enabled module opens TCP 53317" = yes "tcp ${toString lsPort} not open: ${builtins.toJSON lsOn.networking.firewall.allowedTCPPorts}" (builtins.elem lsPort lsOn.networking.firewall.allowedTCPPorts);
    "localsend: enabled module opens UDP 53317" = yes "udp ${toString lsPort} not open: ${builtins.toJSON lsOn.networking.firewall.allowedUDPPorts}" (builtins.elem lsPort lsOn.networking.firewall.allowedUDPPorts);
    "localsend: enabled module installs the localsend package system-wide" = yes "programs.localsend.package not in environment.systemPackages" (lsPkgIn lsOn);
    "control: localsend disabled leaves 53317 closed and the program off" = yes "localsend wiring present with the module off" (!(lsWired lsOff) && !(builtins.elem lsPort lsOff.networking.firewall.allowedTCPPorts) && !(builtins.elem lsPort lsOff.networking.firewall.allowedUDPPorts));
  };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
