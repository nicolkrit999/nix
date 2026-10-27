{ host }:
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  sys = flake.nixosConfigurations.${host};
  base = sys.config;
  withLocalsend = on: (sys.extendModules { modules = [{ myconfig.services.localsend.enable = lib.mkForce on; }]; }).config;
  lsOn = withLocalsend true;
  lsOff = withLocalsend false;
  lsPort = 53317;
  lsPkgIn = c: builtins.elem c.programs.localsend.package.pname (pkgNames c.environment.systemPackages);
  lsWired = c: c.programs.localsend.enable && builtins.elem lsPort c.networking.firewall.allowedTCPPorts
    && builtins.elem lsPort c.networking.firewall.allowedUDPPorts && lsPkgIn c;
  has = name: base.specialisation ? ${name};
  spec = name: base.specialisation.${name}.configuration;

  eq = what: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${what}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
  yes = what: cond: if cond then "ok" else "FAIL: ${what}";
  inRule = s: lib.hasInfix s;

  des = [ "hyprland" "niri" "mango" "gnome" "kde" "cosmic" ];

  g = spec "guest";
  uid = g.users.users.guest.uid;
  gid = g.users.groups.guest.gid;
  fsOpts = g.fileSystems."/home/guest".options;
  optVal = key: lib.findFirst (o: lib.hasPrefix "${key}=" o) null fsOpts;
  user = base.myconfig.constants.user;
  lingerDir = "/var/lib/systemd/linger";
  excludedDirs = [ lingerDir "/var/lib/containers" "/var/lib/docker" "/var/lib/flatpak" "/var/lib/snapper" "/var/lib/tailscale" ];
  offUnits = [ "flatpak-managed-install" "nh-clean" "snapperd" "snapper-timeline" "snapper-cleanup" "cleanup-trash" ];
  persistDirs = c: map (d: d.directory) c.environment.persistence."/persist".directories;
  lingerTwin = sys.extendModules { modules = [{ environment.persistence."/persist".directories = excludedDirs; }]; };
  lt = lingerTwin.config;
  ltg = lt.specialisation.guest.configuration;
  patMode = c: c.sops.secrets.github_fg_pat_token_nix.mode;
  patTwin = sys.extendModules { modules = [{ sops.secrets.github_fg_pat_token_nix.mode = "0444"; }]; };
  kritOffPaths = [
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
  kritEnable = c: p: lib.attrByPath ([ "myconfig" "krit" ] ++ p ++ [ "enable" ]) false c;
  exposure = [
    (c: c.myconfig.services.tailscale.enable)
    (c: c.myconfig.services.localsend.enable)
    (c: c.services.openssh.enable)
    (c: c.services.avahi.enable)
    (c: c.virtualisation.docker.enable)
    (c: c.virtualisation.podman.enable)
  ];
  kritTwinPaths = lib.filter (p: lib.hasAttrByPath ([ "myconfig" "krit" ] ++ p) sys.options) kritOffPaths;
  w = lib.mkOverride 75;
  on = path: lib.setAttrByPath (path ++ [ "enable" ]) (w true);
  exposureTwin = sys.extendModules {
    modules =
      map (p: on ([ "myconfig" "krit" ] ++ p)) kritTwinPaths
      ++ map (d: on [ "myconfig" "programs" d ]) des
      ++ map on [
        [ "myconfig" "programs" "openlogi" ]
        [ "myconfig" "programs" "thunderbird" ]
        [ "myconfig" "services" "tailscale" ]
        [ "myconfig" "services" "localsend" ]
        [ "services" "openssh" ]
        [ "services" "avahi" ]
        [ "virtualisation" "docker" ]
        [ "virtualisation" "podman" ]
      ]
      ++ [{
        services.tailscale.openFirewall = w true;
        networking.firewall.trustedInterfaces = w [ "tailscale0" ];
      }];
  };
  xb = exposureTwin.config;
  xg = xb.specialisation.guest.configuration;
  xs = xb.specialisation.secure-travel.configuration;
  tmpRule = lib.findFirst (r: lib.hasInfix "AccountsService/users/guest" r && lib.hasPrefix "f " r) "" g.systemd.tmpfiles.rules;

  s = spec "secure-travel";
  sysctl = s.boot.kernel.sysctl;
  sysctlExpected = {
    "kernel.kptr_restrict" = "2";
    "kernel.dmesg_restrict" = "1";
    "kernel.sysrq" = "4";
    "kernel.perf_event_paranoid" = "3";
    "kernel.unprivileged_bpf_disabled" = "1";
    "net.core.bpf_jit_harden" = "2";
    "kernel.yama.ptrace_scope" = "2";
    "net.ipv4.conf.all.accept_redirects" = "0";
    "net.ipv4.conf.default.accept_redirects" = "0";
    "net.ipv6.conf.all.accept_redirects" = "0";
    "net.ipv6.conf.default.accept_redirects" = "0";
    "net.ipv4.conf.all.send_redirects" = "0";
    "net.ipv4.conf.default.send_redirects" = "0";
    "net.ipv4.conf.all.accept_source_route" = "0";
    "net.ipv4.conf.default.accept_source_route" = "0";
    "net.ipv6.conf.all.accept_source_route" = "0";
    "net.ipv6.conf.default.accept_source_route" = "0";
    "net.ipv4.conf.all.rp_filter" = "1";
    "net.ipv4.conf.default.rp_filter" = "1";
    "net.ipv4.icmp_echo_ignore_broadcasts" = "1";
    "net.ipv4.tcp_syncookies" = "1";
    "net.ipv4.conf.all.log_martians" = "1";
    "net.ipv4.conf.default.log_martians" = "1";
  };
  sysctlChecks = lib.mapAttrs'
    (k: v: lib.nameValuePair "secure-travel: sysctl ${k} == ${v}"
      (eq "sysctl ${k}" (if sysctl ? ${k} then toString sysctl.${k} else "MISSING") v))
    sysctlExpected;

  pkgNames = pkgs: map (p: p.pname or p.name or "") pkgs;
  hasTor = builtins.elem "tor-browser" (pkgNames s.environment.systemPackages);
  hasTrayscale = builtins.elem "trayscale" (pkgNames s.home-manager.users.${user}.home.packages);
  isX86 = s.nixpkgs.hostPlatform.isx86_64 or (builtins.match "x86_64.*" s.nixpkgs.hostPlatform.system != null);

  stUser = s.home-manager.users.${user}.systemd.user;
  stWarnExec = lib.concatStringsSep " " (lib.toList (stUser.services.secure-travel-exitnode-warn.Service.ExecStart or ""));
  isProton = n: lib.hasInfix "proton" (lib.toLower n) && (lib.hasInfix "vpn" (lib.toLower n));
  protonPkgs = builtins.filter isProton (pkgNames s.environment.systemPackages ++ pkgNames s.home-manager.users.${user}.home.packages);
  autostartNames = c: builtins.filter (lib.hasPrefix "xdg/autostart/") (builtins.attrNames c.environment.etc);
  protonAutostart = builtins.filter isProton (autostartNames s)
    ++ builtins.filter (n: lib.hasPrefix "autostart/" n && isProton n) (builtins.attrNames (s.home-manager.users.${user}.xdg.configFile or { }));

  ent = spec "entertainment";

  specChecks = lib.listToAttrs (map
    (n: lib.nameValuePair "${n}: no failing assertions"
      (
        let bad = map (a: a.message) (builtins.filter (a: !a.assertion) (spec n).assertions);
        in if bad == [ ] then "ok" else "FAIL: ${n}: ${builtins.concatStringsSep " | " bad}"
      ))
    (builtins.attrNames base.specialisation));

  guestChecks = {
    "guest: users.users.guest.uid == 2000" = eq "guest uid" uid 2000;
    "guest: users.groups.guest.gid == guest uid" = eq "guest gid" gid uid;
    "guest: /home/guest tmpfs uid= matches user uid" = eq "uid opt" (optVal "uid") "uid=${toString uid}";
    "guest: /home/guest tmpfs gid= matches group gid" = eq "gid opt" (optVal "gid") "gid=${toString gid}";
    "guest: /home/guest tmpfs mode=700" = yes "mode=700 missing" (builtins.elem "mode=700" fsOpts);
    "guest: /home/guest is tmpfs and nosuid,nodev" =
      yes "fsType/nosuid/nodev" (g.fileSystems."/home/guest".fsType == "tmpfs" && builtins.elem "nosuid" fsOpts && builtins.elem "nodev" fsOpts);
    "guest: systemd slice user-<uid> declared" = yes "slice user-${toString uid} missing" (g.systemd.slices ? "user-${toString uid}");
    "guest: myconfig.services.tailscale disabled" = eq "myconfig tailscale" g.myconfig.services.tailscale.enable false;
    "guest: services.tailscale disabled" = eq "services.tailscale" g.services.tailscale.enable false;
    "guest: myconfig.services.localsend disabled" = eq "localsend" g.myconfig.services.localsend.enable false;
    "guest: openssh disabled" = eq "openssh" g.services.openssh.enable false;
    "guest: avahi disabled" = eq "avahi" g.services.avahi.enable false;
    "guest: docker disabled" = eq "docker" g.virtualisation.docker.enable false;
    "guest: podman disabled" = eq "podman" g.virtualisation.podman.enable false;
    "guest: nix allowed-users is only the main user" = eq "allowed-users" g.nix.settings.allowed-users [ user ];
    "guest: github PAT secret mode is 0400" = eq "PAT mode" (patMode g) "0400";
    "guest: /persist does not persist linger, docker, containers, tailscale, flatpak, snapper" =
      yes "guest persists ${toString (lib.filter (d: builtins.elem d (persistDirs g) || builtins.elem d (persistDirs ltg)) excludedDirs)}" (lib.all (d: !(builtins.elem d (persistDirs g)) && !(builtins.elem d (persistDirs ltg))) excludedDirs);
    "guest: flatpak install, nh clean, snapper and autotrash units are gone" =
      yes "guest still has units ${toString (lib.filter (n: g.systemd.services ? ${n} || g.systemd.timers ? ${n}) offUnits)}" (lib.all (n: !(g.systemd.services ? ${n}) && !(g.systemd.timers ? ${n})) offUnits);
    "guest: openlogi and thunderbird modules are off" =
      eq "openlogi/thunderbird" [ g.myconfig.programs.openlogi.enable g.myconfig.programs.thunderbird.enable ] [ false false ];
    "control: base has the nh clean and snapper units" =
      yes "base lacks the units, guest absence check is vacuous" (base.systemd.services ? nh-clean && base.systemd.services ? snapperd);
    "guest: /persist keeps the other persisted directories" =
      yes "guest persist list ${builtins.toJSON (persistDirs ltg)} lost entries of ${builtins.toJSON (persistDirs lt)}"
        (lib.subtractLists excludedDirs (persistDirs lt) == persistDirs ltg && persistDirs ltg != [ ]);
    "guest: extraGroups are audio and video only" = eq "extraGroups" (lib.sort lib.lessThan g.users.users.guest.extraGroups) [ "audio" "video" ];
    "guest: no zenity in systemPackages" = yes "zenity installed system-wide" (!(builtins.elem "zenity" (pkgNames g.environment.systemPackages)));
    "guest: welcome autostart still exists" = yes "guest-welcome autostart missing" (g.environment.etc ? "xdg/autostart/guest-welcome.desktop");
    "control: twin base exposes every service the guest must turn off" = yes "twin base lacks some of tailscale/localsend/ssh/avahi/docker/podman" (builtins.all (f: f xb) exposure);
    "guest (twin): every exposure service the base turns on is off" = yes "still on in guest: ${toString (lib.imap0 (i: f: if f xg then toString i else "") exposure)}" (!(builtins.any (f: f xg) exposure));
    "control: twin base has openlogi and thunderbird on" = eq "twin base openlogi/thunderbird" [ xb.myconfig.programs.openlogi.enable xb.myconfig.programs.thunderbird.enable ] [ true true ];
    "guest (twin): openlogi and thunderbird modules are off" = eq "twin guest openlogi/thunderbird" [ xg.myconfig.programs.openlogi.enable xg.myconfig.programs.thunderbird.enable ] [ false false ];
    "control: twin of the host persisting the linger dir has it in its base" = yes "twin does not persist ${lingerDir}, the guest filter is vacuous" (builtins.elem lingerDir (persistDirs lt));
    "control: guest PAT mode override beats a world-readable base mode" = yes "twin base ${patMode patTwin.config}, twin guest ${patMode patTwin.config.specialisation.guest.configuration}" (patMode patTwin.config == "0444" && patMode patTwin.config.specialisation.guest.configuration == "0400");
    "control: base allowed-users differs from the guest" = yes "base allowed-users already ${builtins.toJSON base.nix.settings.allowed-users}" (base.nix.settings.allowed-users != g.nix.settings.allowed-users);
    "control: base keeps networkmanager or another group the guest drops" = yes "base user groups already minimal" (builtins.elem "networkmanager" base.users.users.${user}.extraGroups);
    "control: twin base enables every krit nas/cloud/mount module" = yes "twin base lacks ${toString (map (lib.concatStringsSep ".") (lib.filter (p: !(kritEnable xb p)) kritTwinPaths))}" (kritTwinPaths != [ ] && builtins.all (p: kritEnable xb p) kritTwinPaths);
    "guest (twin): every krit nas/cloud/mount module is off" = yes "still on in guest: ${toString (map (lib.concatStringsSep ".") (lib.filter (p: kritEnable xg p) kritTwinPaths))}" (!(builtins.any (p: kritEnable xg p) kritTwinPaths));
    "guest: autoLogin enabled for guest" = eq "autoLogin" [ g.services.displayManager.autoLogin.enable g.services.displayManager.autoLogin.user ] [ true "guest" ];
    "guest: autoLogin user exists in users.users" = yes "autoLogin user missing" (g.users.users ? ${g.services.displayManager.autoLogin.user});
    "guest: defaultSession == xfce" = eq "defaultSession" g.services.displayManager.defaultSession "xfce";
    "guest: xfce desktop manager enabled" = eq "xfce" g.services.xserver.desktopManager.xfce.enable true;
    "guest: not in wheel" = yes "guest has wheel" (!(builtins.elem "wheel" g.users.users.guest.extraGroups));
    "guest: AccountsService rule has escaped \\n (no real newline)" =
      yes "rule=${builtins.toJSON tmpRule}" (inRule "[User]\\nSession=xfce\\n" tmpRule && !(inRule "\n" tmpRule));
    "guest: AccountsService session matches defaultSession" =
      yes "session mismatch" (inRule "Session=${g.services.displayManager.defaultSession}\\n" tmpRule);
    "guest: stylix disabled" = eq "stylix" g.myconfig.stylix.enable false;
    "guest: bluetooth disabled" = eq "bluetooth" g.myconfig.bluetooth.enable false;
    "guest: tags contain guest" = yes "tags" (builtins.elem "guest" g.system.nixos.tags);
    "control: base config has no guest user" = yes "guest leaked into base" (!(base.users.users ? guest));
    "control: twin base has every DE enabled" = yes "twin base DE flags ${builtins.toJSON (map (d: xb.myconfig.programs.${d}.enable) des)}" (builtins.all (d: xb.myconfig.programs.${d}.enable) des);
    "guest (twin): no DE of the twin base stays enabled" = yes "guest DE flags ${builtins.toJSON (map (d: xg.myconfig.programs.${d}.enable) des)}" (!(builtins.any (d: xg.myconfig.programs.${d}.enable) des));
  } // lib.listToAttrs (map
    (d: lib.nameValuePair "guest: myconfig.programs.${d} disabled" (eq d g.myconfig.programs.${d}.enable false))
    des)
  // lib.listToAttrs (map
    (p: lib.nameValuePair "guest: myconfig.krit.${lib.concatStringsSep "." p} disabled" (eq (lib.concatStringsSep "." p) (kritEnable g p) false))
    kritOffPaths);

  stChecks = sysctlChecks // {
    "secure-travel: root hashedPassword == !" = eq "root pw" s.users.users.root.hashedPassword "!";
    "secure-travel: root hashedPasswordFile == null" = eq "root pwfile" s.users.users.root.hashedPasswordFile null;
    "secure-travel: firewall enabled" = eq "firewall" s.networking.firewall.enable true;
    "secure-travel: firewall allowedTCPPorts == []" = eq "tcp" s.networking.firewall.allowedTCPPorts [ ];
    "secure-travel: firewall allowedUDPPorts == []" = eq "udp" s.networking.firewall.allowedUDPPorts [ ];
    "secure-travel: logRefusedPackets" = eq "logRefusedPackets" s.networking.firewall.logRefusedPackets true;
    "secure-travel: NM wifi macAddress random" = eq "wifi mac" s.networking.networkmanager.wifi.macAddress "random";
    "secure-travel: NM ethernet macAddress random" = eq "eth mac" s.networking.networkmanager.ethernet.macAddress "random";
    "secure-travel: resolved DNSOverTLS opportunistic" = eq "DoT" s.services.resolved.settings.Resolve.DNSOverTLS "opportunistic";
    "secure-travel: tor-browser installed (x86_64)" = if isX86 then yes "tor-browser missing" hasTor else "ok";
    "secure-travel: trayscale in krit home.packages" = yes "trayscale missing" hasTrayscale;
    "secure-travel: no NM dispatcher scripts" = eq "dispatcher count" (builtins.length s.networking.networkmanager.dispatcherScripts) 0;
    "secure-travel: myconfig.services.tailscale.enable == true" = eq "myconfig tailscale" s.myconfig.services.tailscale.enable true;
    "secure-travel: services.tailscale.enable == true" = eq "services.tailscale.enable" s.services.tailscale.enable true;
    "secure-travel: tailscale openFirewall == false" = eq "openFirewall" s.services.tailscale.openFirewall false;
    "secure-travel: firewall trustedInterfaces == [ lo ]" = eq "trustedInterfaces" s.networking.firewall.trustedInterfaces [ "lo" ];
    "secure-travel: bluetooth stays enabled" = eq "bluetooth" [ s.hardware.bluetooth.enable s.services.blueman.enable ] [ true true ];
    "secure-travel: bluetooth radio off at boot" = eq "powerOnBoot" s.hardware.bluetooth.powerOnBoot false;
    "secure-travel: exit node warn user service exists" = yes "service secure-travel-exitnode-warn missing" (stUser.services ? secure-travel-exitnode-warn);
    "secure-travel: exit node warn service runs the warn script" =
      yes "ExecStart=${stWarnExec}" (lib.hasInfix "secure-travel-exitnode-warn" stWarnExec);
    "secure-travel: exit node warn timer is 45s then every 2min" =
      eq "timer" (stUser.timers.secure-travel-exitnode-warn.Timer or { }) { OnActiveSec = "45s"; OnUnitActiveSec = "2min"; };
    "secure-travel: exit node warn timer starts with the graphical session" =
      eq "WantedBy" (stUser.timers.secure-travel-exitnode-warn.Install.WantedBy or [ ]) [ "graphical-session.target" ];
    "secure-travel: no proton vpn package" = yes "proton vpn package present: ${builtins.toJSON protonPkgs}" (protonPkgs == [ ]);
    "secure-travel: no protonvpn autostart entry" = yes "autostart entries: ${builtins.toJSON protonAutostart}" (protonAutostart == [ ]);
    "control: proton vpn detector matches vpn names only" = yes "detector wrong" (isProton "proton-vpn-gtk" && isProton "protonvpn.desktop" && isProton "ProtonVPN" && !(isProton "proton-drive") && !(isProton "tor-browser"));
    "control: guest spec autostart detector sees entries" = yes "etc autostart detector finds nothing in guest" (autostartNames g != [ ]);
    "control: base secure-travel has no exit node warn unit" = yes "base already has the warn unit" (!(base.home-manager.users.${user}.systemd.user.services ? secure-travel-exitnode-warn));
    "control: twin base trusts tailscale0 (secure-travel [ lo ] is an override)" = yes "twin base trustedInterfaces ${builtins.toJSON xb.networking.firewall.trustedInterfaces}" (builtins.elem "tailscale0" xb.networking.firewall.trustedInterfaces);
    "control: twin base opens the tailscale firewall (secure-travel false is an override)" = eq "twin base openFirewall" xb.services.tailscale.openFirewall true;
    "secure-travel (twin): tailscale firewall closed and only lo trusted" = eq "twin secure-travel firewall" [ xs.services.tailscale.openFirewall xs.networking.firewall.trustedInterfaces ] [ false [ "lo" ] ];
    "secure-travel (twin): docker and localsend off while the twin base has them on" = eq "twin secure-travel docker/localsend" [ xb.virtualisation.docker.enable xs.virtualisation.docker.enable xb.myconfig.services.localsend.enable xs.myconfig.services.localsend.enable ] [ true false true false ];
    "secure-travel (twin): gnome is the only DE while the twin base has all" = eq "twin secure-travel DE flags" (map (d: xs.myconfig.programs.${d}.enable) des) (map (d: d == "gnome") des);
    "secure-travel: tailscale0 not a trusted interface" =
      yes "tailscale0 trusted" (!(builtins.elem "tailscale0" s.networking.firewall.trustedInterfaces));
    "secure-travel: gnome is the only DE" =
      eq "DE flags" (map (d: s.myconfig.programs.${d}.enable) des) (map (d: d == "gnome") des);
    "secure-travel: docker disabled" = eq "docker" s.virtualisation.docker.enable false;
    "secure-travel: resolved LLMNR off" = eq "LLMNR" s.services.resolved.settings.Resolve.LLMNR "false";
    "secure-travel: resolved MulticastDNS off" = eq "MulticastDNS" s.services.resolved.settings.Resolve.MulticastDNS "false";
    "secure-travel: resolved has no global ~. routing domain" =
      yes "Domains=${builtins.toJSON s.services.resolved.settings.Resolve.Domains}"
        (!(builtins.elem "~." (let d = s.services.resolved.settings.Resolve.Domains; in if builtins.isList d then d else [ d ])));
    "secure-travel: gnome-remote-desktop disabled" = eq "grd" s.services.gnome.gnome-remote-desktop.enable false;
    "secure-travel: gnome-user-share disabled" = eq "gus" s.services.gnome.gnome-user-share.enable false;
    "secure-travel: myconfig.services.localsend.enable == false" = eq "myconfig localsend" s.myconfig.services.localsend.enable false;
    "secure-travel: programs.localsend.enable == false" = eq "programs.localsend" s.programs.localsend.enable false;
    "localsend: enabled module sets programs.localsend.enable" = eq "programs.localsend" lsOn.programs.localsend.enable true;
    "localsend: enabled module opens TCP 53317" = yes "tcp ${toString lsPort} not open: ${builtins.toJSON lsOn.networking.firewall.allowedTCPPorts}" (builtins.elem lsPort lsOn.networking.firewall.allowedTCPPorts);
    "localsend: enabled module opens UDP 53317" = yes "udp ${toString lsPort} not open: ${builtins.toJSON lsOn.networking.firewall.allowedUDPPorts}" (builtins.elem lsPort lsOn.networking.firewall.allowedUDPPorts);
    "localsend: enabled module installs the localsend package system-wide" = yes "programs.localsend.package not in environment.systemPackages" (lsPkgIn lsOn);
    "control: localsend disabled leaves 53317 closed and the program off" = yes "localsend wiring present with the module off" (!(lsWired lsOff) && !(builtins.elem lsPort lsOff.networking.firewall.allowedTCPPorts) && !(builtins.elem lsPort lsOff.networking.firewall.allowedUDPPorts));
    "secure-travel: tags contain secure-travel" = yes "tags" (builtins.elem "secure-travel" s.system.nixos.tags);
    "control: base root account differs from secure-travel" = yes "base already locked" (base.users.users.root.hashedPassword != "!" || base.users.users.root.hashedPasswordFile != null);
    "control: check helper detects mismatch" = yes "helper broken" (lib.hasPrefix "FAIL" (eq "x" 1 2));
  };

  entChecks = {
    "entertainment: only kde enabled among DEs" =
      eq "DE flags" (map (d: ent.myconfig.programs.${d}.enable) des) (map (d: d == "kde") des);
    "entertainment: tags contain entertainment" = yes "tags" (builtins.elem "entertainment" ent.system.nixos.tags);
  };

  checks =
    {
      "control: guest spec declares guest user (specs are separate evals)" = yes "guest spec missing" (has "guest");
    }
    // specChecks // guestChecks // stChecks // (lib.optionalAttrs (has "entertainment") entChecks);

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
