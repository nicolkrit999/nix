{ host }:
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  base = flake.nixosConfigurations.${host}.config;
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
  fw = g.networking.firewall.extraCommands;
  fwLines = lib.splitString "\n" fw;
  uidLines = builtins.filter (l: lib.hasInfix "--uid-owner ${toString uid}" l) fwLines;
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
  isX86 = s.nixpkgs.hostPlatform.isx86_64 or (builtins.match "x86_64.*" s.nixpkgs.hostPlatform.system != null);

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
    "guest: firewall blocks guest uid to tailscale0" =
      yes "no REJECT for tailscale0" (builtins.any (l: lib.hasInfix "-o tailscale0" l && lib.hasInfix "-j REJECT" l) uidLines);
    "guest: firewall blocks guest uid to 100.64.0.0/10" =
      yes "no REJECT for 100.64.0.0/10" (builtins.any (l: lib.hasInfix "-d 100.64.0.0/10" l && lib.hasInfix "-j REJECT" l) uidLines);
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
    "control: base config has a DE enabled" = yes "no DE in base" (builtins.any (d: base.myconfig.programs.${d}.enable) des);
  } // lib.listToAttrs (map
    (d: lib.nameValuePair "guest: myconfig.programs.${d} disabled" (eq d g.myconfig.programs.${d}.enable false))
    des);

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
    "secure-travel: one NM dispatcher script (killswitch)" = eq "dispatcher count" (builtins.length s.networking.networkmanager.dispatcherScripts) 1;
    "secure-travel: myconfig.services.tailscale.enable == false" = eq "myconfig tailscale" s.myconfig.services.tailscale.enable false;
    "secure-travel: services.tailscale.enable == false" = eq "services.tailscale.enable" s.services.tailscale.enable false;
    "secure-travel: tailscale0 not a trusted interface" =
      yes "tailscale0 trusted" (!(builtins.elem "tailscale0" s.networking.firewall.trustedInterfaces));
    "secure-travel: gnome is the only DE" =
      eq "DE flags" (map (d: s.myconfig.programs.${d}.enable) des) (map (d: d == "gnome") des);
    "secure-travel: docker disabled" = eq "docker" s.virtualisation.docker.enable false;
    "secure-travel: resolved LLMNR off" = eq "LLMNR" s.services.resolved.settings.Resolve.LLMNR "false";
    "secure-travel: resolved MulticastDNS off" = eq "MulticastDNS" s.services.resolved.settings.Resolve.MulticastDNS "false";
    "secure-travel: gnome-remote-desktop disabled" = eq "grd" s.services.gnome.gnome-remote-desktop.enable false;
    "secure-travel: gnome-user-share disabled" = eq "gus" s.services.gnome.gnome-user-share.enable false;
    "secure-travel: tags contain secure-travel" = yes "tags" (builtins.elem "secure-travel" s.system.nixos.tags);
    "control: base tailscale enabled (secure-travel override is not vacuous)" = eq "base tailscale" base.myconfig.services.tailscale.enable true;
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
  killswitch = builtins.concatStringsSep "\n" (map (d: d.source.text or "") s.networking.networkmanager.dispatcherScripts);
}
