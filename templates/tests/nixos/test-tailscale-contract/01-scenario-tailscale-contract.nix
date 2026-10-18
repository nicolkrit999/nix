let
  host = builtins.getEnv "HOST_UNDER_TEST";
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  sys = flake.nixosConfigurations.${host};
  cfg = sys.config;
  user = cfg.myconfig.constants.user;

  check = cond: detail: if cond then "ok" else "FAIL: ${detail}";
  has = x: xs: builtins.elem x xs;

  ts = cfg.services.tailscale;

  flagName = f: lib.head (lib.splitString "=" (lib.removePrefix "-" (lib.removePrefix "-" f)));
  flagVal = f: let parts = lib.splitString "=" f; in if lib.length parts < 2 then null else lib.concatStringsSep "=" (lib.tail parts);
  falsy = v: has v [ "0" "f" "F" "false" "FALSE" "False" ];
  dnsOff = flags: lib.filter (f: flagName f == "accept-dns" && flagVal f != null && falsy (flagVal f)) flags;
  routesOn = flags: lib.filter (f: flagName f == "accept-routes" && !(flagVal f != null && falsy (flagVal f))) flags;
  allFlags = c: c.services.tailscale.extraUpFlags ++ c.services.tailscale.extraSetFlags;

  school = cfg.specialisation.school.configuration;
  exitOff = school.systemd.services.tailscale-school-exit-node-off;
  offScript = exitOff.script;
  offCfg = exitOff.serviceConfig;
  offLoops = let m = builtins.match ".*seq 1 ([0-9]+).*" offScript; in if m == null then null else lib.toInt (builtins.head m);
  offSleep = let m = builtins.match ".*sleep ([0-9]+).*" offScript; in if m == null then null else lib.toInt (builtins.head m);
  offSetTimeout = let m = builtins.match ".*timeout ([0-9]+) tailscale set.*" offScript; in if m == null then null else lib.toInt (builtins.head m);
  offWorst = if offLoops == null || offSleep == null || offSetTimeout == null then null else offLoops * (offSetTimeout + offSleep);
  offDeps = exitOff.after ++ exitOff.wants;
  offDangling = lib.filter (u: lib.hasSuffix ".service" u && !(school.systemd.services ? ${lib.removeSuffix ".service" u})) offDeps;
  travel = cfg.specialisation.secure-travel.configuration;

  disabled = (sys.extendModules { modules = [{ myconfig.services.tailscale.enable = lib.mkForce false; }]; }).config;
  otherUser = (sys.extendModules { modules = [{ myconfig.constants.user = lib.mkForce "ctrluser"; }]; }).config;

  checks = {
    check-operator-set-flag = check (has "--operator=${user}" cfg.services.tailscale.extraSetFlags)
      "extraSetFlags: ${builtins.toJSON cfg.services.tailscale.extraSetFlags}";
    check-operator-up-flag = check (has "--operator=${user}" cfg.services.tailscale.extraUpFlags)
      "extraUpFlags: ${builtins.toJSON cfg.services.tailscale.extraUpFlags}";
    check-operator-flags-agree = check
      (lib.filter (lib.hasPrefix "--operator=") cfg.services.tailscale.extraSetFlags == lib.filter (lib.hasPrefix "--operator=") cfg.services.tailscale.extraUpFlags
        && lib.filter (lib.hasPrefix "--operator=") cfg.services.tailscale.extraSetFlags != [ ])
      "set vs up operator flags differ";
    check-operator-control-follows-user = check
      (has "--operator=ctrluser" otherUser.services.tailscale.extraSetFlags && has "--operator=ctrluser" otherUser.services.tailscale.extraUpFlags
        && !(has "--operator=${user}" otherUser.services.tailscale.extraSetFlags))
      "operator flag does not follow constants.user";
    check-firewall-trusted-iface = check (has "tailscale0" cfg.networking.firewall.trustedInterfaces)
      "tailscale0 not trusted";
    check-firewall-loose-rpfilter = check (cfg.networking.firewall.checkReversePath == "loose")
      "checkReversePath = ${toString cfg.networking.firewall.checkReversePath}";
    check-firewall-udp-41641 = check (has 41641 cfg.networking.firewall.allowedUDPPorts) "udp 41641 not open";
    check-authkeyfile-set = check (ts.authKeyFile != null) "services.tailscale.authKeyFile is null (no upstream tailscaled-autoconnect login)";
    check-upstream-autoconnect-exists = check (cfg.systemd.services ? tailscaled-autoconnect) "no upstream tailscaled-autoconnect unit";
    check-upstream-autoconnect-control-absent-when-disabled = check (!(disabled.systemd.services ? tailscaled-autoconnect))
      "tailscaled-autoconnect exists with the module disabled";
    check-no-repo-autoconnect-unit = check (!(cfg.systemd.services ? tailscale-autoconnect)) "removed repo unit tailscale-autoconnect is back";
    check-no-accept-dns-false = check (dnsOff (allFlags cfg) == [ ] && dnsOff (allFlags school) == [ ])
      "accept-dns disabled (tailnet DNS SPOF rule): ${builtins.toJSON (dnsOff (allFlags cfg) ++ dnsOff (allFlags school))}";
    check-no-accept-routes = check (routesOn (allFlags cfg) == [ ] && routesOn (allFlags school) == [ ])
      "accept-routes enabled (NAS advertises the home LAN): ${builtins.toJSON (routesOn (allFlags cfg) ++ routesOn (allFlags school))}";
    check-flag-detectors-control = check
      (dnsOff [ "--accept-dns=false" ] != [ ] && dnsOff [ "-accept-dns=0" ] != [ ] && dnsOff [ "--accept-dns" "--accept-dns=true" ] == [ ]
        && routesOn [ "--accept-routes" ] != [ ] && routesOn [ "--accept-routes=true" ] != [ ] && routesOn [ "--accept-routes=false" ] == [ ])
      "accept-dns/accept-routes flag detectors are broken";
    check-school-no-repo-autoconnect-unit = check (!(school.systemd.services ? tailscale-autoconnect)) "school has the removed repo unit tailscale-autoconnect";
    check-school-has-upstream-autoconnect = check (school.systemd.services ? tailscaled-autoconnect) "school lacks upstream tailscaled-autoconnect";
    check-school-exitoff-ordering-units = check
      (has "tailscaled.service" exitOff.after && !(has "tailscale-autoconnect.service" offDeps) && offDangling == [ ])
      "after=${builtins.toJSON exitOff.after} wants=${builtins.toJSON exitOff.wants} dangling=${builtins.toJSON offDangling}";
    check-school-exitoff-path-service-package = check (has school.services.tailscale.package exitOff.path)
      "exit-off path does not contain services.tailscale.package";
    check-school-exitoff-wantedby = check (has "multi-user.target" exitOff.wantedBy) "wantedBy=${builtins.toJSON exitOff.wantedBy}";
    check-school-exitoff-script = check (lib.hasInfix "tailscale set --exit-node=" exitOff.script) "exit-node reset missing";
    check-school-exitoff-not-blocking-oneshot = check
      ((offCfg.Type or "simple") != "oneshot" && has "multi-user.target" exitOff.wantedBy)
      "exit-off Type=${offCfg.Type or "unset"} wantedBy=${builtins.toJSON exitOff.wantedBy} (a oneshot wanted by multi-user.target blocks boot)";
    check-school-exitoff-type-exec = check ((offCfg.Type or "") == "exec") "exit-off Type=${offCfg.Type or "unset"}";
    check-school-exitoff-loop-bounded = check
      (offWorst != null && offLoops <= 100 && offWorst <= 900)
      "exit-off loop unbounded or too long: loops=${toString offLoops} sleep=${toString offSleep} set-timeout=${toString offSetTimeout} worst=${toString offWorst}s";
    check-school-exitoff-gives-up = check (lib.hasInfix "exit 1" offScript) "exit-off never fails after the retries are exhausted";
    check-school-exitoff-after-tailscaled-prefs-edit = check
      (has "tailscaled.service" exitOff.after && lib.hasInfix "tailscale set --exit-node=" exitOff.script && !(lib.hasInfix "tailscale up" exitOff.script))
      "after=${builtins.toJSON exitOff.after}; script must be a prefs edit (tailscale set) ordered after tailscaled";
    check-secure-travel-tailscale-on = check (travel.myconfig.services.tailscale.enable && travel.services.tailscale.enable)
      "tailscale is the secure-travel VPN but is off (wrapper=${lib.boolToString travel.myconfig.services.tailscale.enable}, service=${lib.boolToString travel.services.tailscale.enable})";
    check-secure-travel-autoconnect-allowed = check (travel.systemd.services ? tailscaled-autoconnect && !(travel.systemd.services ? tailscale-autoconnect))
      "secure-travel needs the upstream tailscaled-autoconnect and not the removed repo unit";
    check-secure-travel-no-open-firewall = check (!travel.services.tailscale.openFirewall && !(has 41641 travel.networking.firewall.allowedUDPPorts))
      "secure-travel is outbound only: openFirewall=${lib.boolToString travel.services.tailscale.openFirewall}, udp ${builtins.toJSON travel.networking.firewall.allowedUDPPorts}";
    check-secure-travel-control-base-opens-firewall = check ts.openFirewall
      "base host does not open the tailscale port, so the secure-travel no-open-firewall check is vacuous";
    check-secure-travel-tailscale0-untrusted = check (!(has "tailscale0" travel.networking.firewall.trustedInterfaces)) "tailscale0 trusted in secure-travel";
  };
in
checks
