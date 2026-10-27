let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  fx = import ../../lib/fixture-host.nix flake;
  niriFixture = (fx.mkNixos [{ myconfig.programs.niri.enable = lib.mkForce true; }]).config;

  hostNames = [ "nixos-desktop" "nixos-laptop" ];
  hmOf = c: c.home-manager.users.krit;
  enabled = c: n: c.myconfig.programs.${n}.enable or false;

  variants = lib.listToAttrs (lib.concatMap
    (h:
      let c = flake.nixosConfigurations.${h}.config; in
      [{ name = h; value = c; }]
      ++ map
        (n: { name = "${h}+${n}"; value = c.specialisation.${n}.configuration; })
        (builtins.attrNames c.specialisation))
    hostNames);

  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  isFail = lib.hasPrefix "FAIL";

  niriFacts = c:
    let
      settings = (hmOf c).programs.niri.settings;
      sysUnits = c.systemd.user.services;
    in
    {
      startup = map (s: s.command) settings.spawn-at-startup;
      inherit (settings) environment;
      xwaylandSatellite = settings.xwayland-satellite;
      niriFlakePolkit = sysUnits.niri-flake-polkit.enable;
      otherPolkitUnits = lib.filter (n: n != "niri-flake-polkit" && lib.hasInfix "polkit" (lib.toLower n) && sysUnits.${n}.enable) (builtins.attrNames sysUnits);
      hmAgentServices = lib.filter (n: (hmOf c).services.${n}.enable or false) [ "polkit-gnome" "hyprpolkitagent" ];
      sessionDisplay = {
        hm = (hmOf c).home.sessionVariables.DISPLAY or null;
        sysVariables = c.environment.variables.DISPLAY or null;
        sysSession = c.environment.sessionVariables.DISPLAY or null;
      };
    };

  cmdText = lib.concatStringsSep " ";
  isAgentSpawn = cmd: builtins.match ".*polkit.*agent.*" (lib.toLower (cmdText cmd)) != null;

  sessionChecks = f:
    let
      spawnedAgents = lib.filter isAgentSpawn f.startup;
      agentCount =
        (if f.niriFlakePolkit then 1 else 0)
        + builtins.length f.otherPolkitUnits
        + builtins.length f.hmAgentServices
        + builtins.length spawnedAgents;
      manualSatellite = lib.filter (cmd: lib.hasInfix "xwayland-satellite" (cmdText cmd)) f.startup;
      displayInSpawn = lib.filter (cmd: lib.hasInfix "DISPLAY=" (cmdText cmd)) f.startup;
      displaySet = lib.filter (n: f.sessionDisplay.${n} != null) (builtins.attrNames f.sessionDisplay);
    in
    {
      "niri-exactly-one-polkit-agent" = chk (agentCount == 1)
        "${toString agentCount} polkit agents in the niri session (niri-flake unit enabled: ${lib.boolToString f.niriFlakePolkit}, other units: [${toString f.otherPolkitUnits}], HM agent services: [${toString f.hmAgentServices}], spawned: ${toString (builtins.length spawnedAgents)})";
      "niri-flake-polkit-unit-disabled-if-agent-spawned" = chk (spawnedAgents == [ ] || !f.niriFlakePolkit)
        "niri spawns a polkit agent while niri-flake-polkit.service is also enabled";
      "niri-no-manual-xwayland-satellite" = chk (manualSatellite == [ ])
        "spawn-at-startup runs xwayland-satellite by hand: ${lib.concatMapStringsSep " | " cmdText manualSatellite}";
      "niri-builtin-xwayland-satellite-enabled" = chk (f.xwaylandSatellite.enable == true)
        "programs.niri.settings.xwayland-satellite.enable is not true";
      "niri-no-hardcoded-display-in-niri-env" = chk (!(f.environment ? DISPLAY) && displayInSpawn == [ ])
        "niri environment sets DISPLAY or a spawn passes DISPLAY=: ${lib.concatMapStringsSep " | " cmdText displayInSpawn}";
      "niri-no-hardcoded-display-in-session-vars" = chk (displaySet == [ ])
        "DISPLAY is set in: ${toString displaySet}";
    };

  realResults = lib.filterAttrs (_: v: v != { })
    (lib.mapAttrs (_: c: lib.optionalAttrs (enabled c "niri") (sessionChecks (niriFacts c))) variants);
  results = { fixture-niri = sessionChecks (niriFacts niriFixture); } // realResults;

  real = niriFacts niriFixture;
  mut = f: sessionChecks (real // f);
  withoutAgentSpawn = lib.filter (cmd: !(isAgentSpawn cmd)) real.startup;
  agentCmd = [ "/nix/store/x-polkit-gnome/libexec/polkit-gnome-authentication-agent-1" ];
in
{
  inherit results;

  control = {
    "baseline-fixture-has-one-agent" =
      chk ((mut { })."niri-exactly-one-polkit-agent" == "ok") "unmutated fixture niri facts no longer show exactly one agent";
    "polkit-two-agents-fails" =
      chk (isFail (mut { niriFlakePolkit = true; startup = withoutAgentSpawn ++ [ agentCmd ]; })."niri-exactly-one-polkit-agent") "niri-flake unit + spawned agent not flagged";
    "polkit-unit-plus-spawn-pair-fails" =
      chk (isFail (mut { niriFlakePolkit = true; startup = withoutAgentSpawn ++ [ agentCmd ]; })."niri-flake-polkit-unit-disabled-if-agent-spawned") "enabled unit next to a spawned agent not flagged";
    "polkit-zero-agents-fails" =
      chk (isFail (mut { niriFlakePolkit = false; startup = withoutAgentSpawn; })."niri-exactly-one-polkit-agent") "no polkit agent at all not flagged";
    "polkit-unit-only-passes" =
      chk ((mut { niriFlakePolkit = true; startup = withoutAgentSpawn; })."niri-exactly-one-polkit-agent" == "ok") "the niri-flake unit alone is a valid single agent";
    "polkit-extra-hm-service-fails" =
      chk (isFail (mut { hmAgentServices = [ "hyprpolkitagent" ]; })."niri-exactly-one-polkit-agent") "second agent via an HM service not flagged";
    "polkit-extra-system-unit-fails" =
      chk (isFail (mut { otherPolkitUnits = [ "my-polkit-agent" ]; })."niri-exactly-one-polkit-agent") "second agent via another user unit not flagged";
    "xwayland-manual-spawn-fails" =
      chk (isFail (mut { startup = real.startup ++ [ [ "xwayland-satellite" ":1" ] ]; })."niri-no-manual-xwayland-satellite") "manual xwayland-satellite spawn not flagged";
    "xwayland-builtin-disabled-fails" =
      chk (isFail (mut { xwaylandSatellite = { enable = false; path = null; }; })."niri-builtin-xwayland-satellite-enabled") "disabled built-in xwayland-satellite not flagged";
    "display-in-niri-env-fails" =
      chk (isFail (mut { environment = real.environment // { DISPLAY = ":1"; }; })."niri-no-hardcoded-display-in-niri-env") "DISPLAY in niri environment not flagged";
    "display-in-spawn-fails" =
      chk (isFail (mut { startup = real.startup ++ [ [ "env" "DISPLAY=:1" "xterm" ] ]; })."niri-no-hardcoded-display-in-niri-env") "DISPLAY= in a spawn not flagged";
    "display-in-session-vars-fails" =
      chk (isFail (mut { sessionDisplay = real.sessionDisplay // { hm = ":1"; }; })."niri-no-hardcoded-display-in-session-vars") "DISPLAY in sessionVariables not flagged";
  };
}
