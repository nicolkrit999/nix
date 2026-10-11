let host = builtins.getEnv "HOST_UNDER_TEST"; in
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  sys = flake.nixosConfigurations.${host};
  cfg = sys.config;
  user = cfg.myconfig.constants.user;

  check = cond: detail: if cond then "ok" else "FAIL: ${detail}";
  has = x: xs: builtins.elem x xs;

  svc = c: c.systemd.services.tailscale-autoconnect;
  ac = svc cfg;
  acCfg = ac.serviceConfig;
  script = ac.script;

  num = re: let m = builtins.match re script; in if m == null then null else lib.toInt (builtins.head m);
  loops = num ".*seq 1 ([0-9]+).*";
  upTimeout = num ".*tailscale up --timeout=([0-9]+)s.*";
  sleepSec = num ".*sleep ([0-9]+).*";
  worstCase = loops * (upTimeout + sleepSec);

  school = cfg.specialisation.school.configuration;
  exitOff = school.systemd.services.tailscale-school-exit-node-off;
  offScript = exitOff.script;
  offCfg = exitOff.serviceConfig;
  offLoops = let m = builtins.match ".*seq 1 ([0-9]+).*" offScript; in if m == null then null else lib.toInt (builtins.head m);
  offSleep = let m = builtins.match ".*sleep ([0-9]+).*" offScript; in if m == null then null else lib.toInt (builtins.head m);
  offSetTimeout = let m = builtins.match ".*timeout ([0-9]+) tailscale set.*" offScript; in if m == null then null else lib.toInt (builtins.head m);
  offWorst = if offLoops == null || offSleep == null || offSetTimeout == null then null else offLoops * (offSetTimeout + offSleep);
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
    check-autoconnect-unit-exists = check (cfg.systemd.services ? tailscale-autoconnect) "no tailscale-autoconnect unit";
    check-autoconnect-control-absent-when-disabled = check (!(disabled.systemd.services ? tailscale-autoconnect))
      "autoconnect unit exists with module disabled";
    check-autoconnect-type-exec = check (acCfg.Type == "exec") "Type=${acCfg.Type}";
    check-autoconnect-no-misleading-timeout = check (!(acCfg ? TimeoutStartSec)) "TimeoutStartSec set on the Type=exec autoconnect unit (cannot bound the loop)";
    check-autoconnect-wantedby-multiuser = check (has "multi-user.target" ac.wantedBy) "wantedBy=${builtins.toJSON ac.wantedBy}";
    check-autoconnect-after-tailscaled = check (has "tailscaled.service" ac.after && has "network-online.target" ac.after)
      "after=${builtins.toJSON ac.after}";
    check-autoconnect-script-up-timeout = check (lib.hasInfix "tailscale up --timeout=20s" script) "script lacks --timeout=20s";
    check-autoconnect-script-parsed = check (loops != null && upTimeout != null && sleepSec != null)
      "cannot parse loop/timeout/sleep from the autoconnect script";
    check-autoconnect-retry-loop-bounded = check
      (loops != null && upTimeout != null && sleepSec != null && loops <= 100 && worstCase <= 3600)
      "retry loop unbounded or too long: loops=${toString loops} worst=${toString worstCase}s";
    check-autoconnect-gives-up = check (lib.hasInfix "exit 1" script) "script never exits non-zero after the loop";
    check-school-has-autoconnect = check (school.systemd.services ? tailscale-autoconnect) "school lacks autoconnect unit";
    check-school-exitoff-ordering-units = check
      (has "tailscale-autoconnect.service" exitOff.after && has "tailscale-autoconnect.service" exitOff.wants && has "tailscaled.service" exitOff.after)
      "after=${builtins.toJSON exitOff.after} wants=${builtins.toJSON exitOff.wants}";
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
    check-school-autoconnect-nonblocking = check
      (school.systemd.services.tailscale-autoconnect.serviceConfig.Type == "exec")
      "school tailscale-autoconnect Type=${school.systemd.services.tailscale-autoconnect.serviceConfig.Type} (must stay exec, boot hang regression)";
    check-secure-travel-myconfig-tailscale-off = check (!travel.myconfig.services.tailscale.enable) "myconfig.services.tailscale enabled in secure-travel";
    check-secure-travel-nixos-tailscale-off = check (!travel.services.tailscale.enable)
      "services.tailscale.enable true in secure-travel (myconfig wrapper=${lib.boolToString travel.myconfig.services.tailscale.enable}; a NAS consumer still forces it on?)";
    check-secure-travel-no-autoconnect = check (!(travel.systemd.services ? tailscale-autoconnect)) "autoconnect unit present in secure-travel";
    check-secure-travel-tailscale0-untrusted = check (!(has "tailscale0" travel.networking.firewall.trustedInterfaces)) "tailscale0 trusted in secure-travel";
  };
in
checks
