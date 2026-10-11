let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  host = flake.darwinConfigurations.Krits-MacBook-Pro;
  variant = host.extendModules {
    modules = [
      ({ lib, ... }: {
        myconfig.krit.programs.librewolf.enable = lib.mkForce true;
        myconfig.krit.programs.firefox.enable = lib.mkForce true;
      })
    ];
  };

  hasNixos = flake.nixosConfigurations != { };
  forceBrowsers = { lib, ... }: {
    myconfig.krit.programs.librewolf.enable = lib.mkForce true;
    myconfig.krit.programs.firefox.enable = lib.mkForce true;
  };
  linuxNixos = flake.nixosConfigurations.template-host-minimal.extendModules { modules = [ forceBrowsers ]; };
  linuxStandalone = flake.homeConfigurations."krit@template-host-minimal".extendModules { modules = [ forceBrowsers ]; };

  user = host.config.myconfig.constants.user;
  linuxHome = "/home/";

  strs = attrs: lib.filterAttrs (_: v: builtins.isString v) attrs;
  hmOf = config: config.home-manager.users.${user};

  fileTexts = config: lib.filterAttrs (_: t: t != null) (lib.mapAttrs (_: f: f.text or null) (hmOf config).home.file);
  xdgTexts = config: lib.filterAttrs (_: t: t != null) (lib.mapAttrs (_: f: f.text or null) (hmOf config).xdg.configFile);
  sessionVars = config: strs (lib.mapAttrs (_: v: if builtins.isString v || builtins.isInt v then toString v else null) (hmOf config).home.sessionVariables);
  hmActivation = config: lib.mapAttrs (_: a: a.data) (hmOf config).home.activation;
  sysActivation = config: lib.mapAttrs (_: a: a.text) (lib.filterAttrs (n: a: n != "script" && a ? text) config.system.activationScripts);
  sysEnv = config: strs config.environment.variables;
  sopsTemplatePaths = config: lib.mapAttrs (_: t: t.path) config.sops.templates;

  hits = set: builtins.attrNames (lib.filterAttrs (_: t: lib.hasInfix linuxHome t) set);

  check = name: cond: detail:
    if cond then "ok" else "FAIL: ${name}: ${detail}";

  checkClean = name: found:
    check name (found == [ ]) "Linux home path in ${builtins.toJSON found}";

  checkNonEmpty = name: set:
    check name (builtins.length (builtins.attrNames set) > 0) "swept set is empty, sweep is vacuous";

  baseHm = hmOf host.config;
  varHm = hmOf variant.config;
  homeDir = baseHm.home.homeDirectory;

  lwText = varHm.programs.librewolf.package.text;
  lwDistLine = lib.findFirst (l: lib.hasInfix "MOZ_APP_DISTRIBUTION=" l) "" (lib.splitString "\n" lwText);
  lwDist = lib.removeSuffix "\"" (lib.removePrefix "export MOZ_APP_DISTRIBUTION=\"" lwDistLine);

  profileSettings = prog: builtins.toJSON (lib.mapAttrs (_: p: p.settings) varHm.programs.${prog}.profiles);
  varUserJs = lib.filterAttrs (n: _: lib.hasSuffix "/user.js" n && (lib.hasPrefix "Library/Application Support/LibreWolf" n || lib.hasPrefix "Library/Application Support/Firefox" n)) (fileTexts variant.config);

  browserHomeCheck = label: hm: expectedHome:
    let
      settings = prog: lib.mapAttrs (_: p: p.settings) hm.programs.${prog}.profiles;
      dirs = prog: lib.concatMap (s: [ s."browser.download.dir" or "" s."browser.download.lastDir" or "" ]) (builtins.attrValues (settings prog));
      want = "${expectedHome}/Downloads";
      wrongDirs = builtins.filter (d: d != want) (dirs "librewolf" ++ dirs "firefox");
      wrapper = hm.programs.librewolf.package.text;
      distLine = lib.findFirst (l: lib.hasInfix "MOZ_APP_DISTRIBUTION=" l) "" (lib.splitString "\n" wrapper);
      wantRoot = "${expectedHome}/.librewolf-policyroot";
    in
    check "${label}: browser paths follow the platform home (${expectedHome})"
      (hm.home.homeDirectory == expectedHome
        && dirs "librewolf" != [ ] && dirs "firefox" != [ ]
        && wrongDirs == [ ]
        && lib.hasInfix "MOZ_APP_DISTRIBUTION=\"${wantRoot}\"" distLine)
      "home=${hm.home.homeDirectory} wrongDirs=${builtins.toJSON wrongDirs} dist=${distLine}";
in
{
  check-linux-nixos-browser-home = if hasNixos then browserHomeCheck "nixos HM" (hmOf linuxNixos.config) "/home/${user}" else "ok";
  check-linux-standalone-browser-home = if hasNixos then browserHomeCheck "standalone home" linuxStandalone.config "/home/${user}" else "ok";
  check-variant-browser-home = browserHomeCheck "darwin HM" varHm "/Users/${user}";

  check-base-home-dir = check "HM home.homeDirectory is a Darwin home" (lib.hasPrefix "/Users/" homeDir) "got ${homeDir}";

  check-base-file-texts = checkClean "base: no ${linuxHome} in home.file texts" (hits (fileTexts host.config));
  check-base-file-texts-nonvacuous = checkNonEmpty "base: home.file text sweep covers files" (fileTexts host.config);
  check-base-xdg-texts = checkClean "base: no ${linuxHome} in xdg.configFile texts" (hits (xdgTexts host.config));
  check-base-session-vars = checkClean "base: no ${linuxHome} in home.sessionVariables" (hits (sessionVars host.config));
  check-base-hm-activation = checkClean "base: no ${linuxHome} in home.activation" (hits (hmActivation host.config));
  check-base-sys-activation = checkClean "base: no ${linuxHome} in system.activationScripts" (hits (sysActivation host.config));
  check-base-sys-env = checkClean "base: no ${linuxHome} in environment.variables" (hits (sysEnv host.config));
  check-base-sops-template-paths = checkClean "base: no ${linuxHome} in sops.templates paths" (hits (sopsTemplatePaths host.config));
  check-base-sops-template-control =
    check "control: sops.templates sweep sees a path under /Users"
      (builtins.any (p: lib.hasPrefix "/Users/" p) (builtins.attrValues (sopsTemplatePaths host.config)))
      "paths ${builtins.toJSON (sopsTemplatePaths host.config)}";
  check-base-sys-activation-control =
    check "control: system.activationScripts sweep sees a /Users path"
      (builtins.any (t: lib.hasInfix "/Users/" t) (builtins.attrValues (sysActivation host.config)))
      "no activation script mentions /Users, sweep may be vacuous";
  check-base-nh-flake =
    check "programs.nh.flake lives under home.homeDirectory"
      (lib.hasPrefix "${homeDir}/" baseHm.programs.nh.flake)
      "flake=${baseHm.programs.nh.flake}, home=${homeDir}";

  check-variant-control =
    check "control: variant activates librewolf + firefox on Darwin"
      (variant.config.myconfig.krit.programs.librewolf.enable
        && variant.config.myconfig.krit.programs.firefox.enable
        && varHm.programs.librewolf.enable
        && varHm.programs.firefox.enable
        && varHm.home.file ? ".librewolf-policyroot/distribution/policies.json"
        && builtins.length (builtins.attrNames varUserJs) >= 3)
      "variant did not activate the browser modules (userJs=${builtins.toJSON (builtins.attrNames varUserJs)})";

  check-variant-file-texts = checkClean "variant: no ${linuxHome} in home.file texts" (hits (fileTexts variant.config));
  check-variant-xdg-texts = checkClean "variant: no ${linuxHome} in xdg.configFile texts" (hits (xdgTexts variant.config));
  check-variant-session-vars = checkClean "variant: no ${linuxHome} in home.sessionVariables" (hits (sessionVars variant.config));
  check-variant-hm-activation = checkClean "variant: no ${linuxHome} in home.activation" (hits (hmActivation variant.config));
  check-variant-sys-activation = checkClean "variant: no ${linuxHome} in system.activationScripts" (hits (sysActivation variant.config));
  check-variant-firefox-user-js =
    checkClean "variant: no ${linuxHome} in Firefox/LibreWolf user.js" (hits varUserJs);
  check-variant-librewolf-settings =
    check "variant: no ${linuxHome} in programs.librewolf profile settings" (!lib.hasInfix linuxHome (profileSettings "librewolf")) "found in ${profileSettings "librewolf"}";
  check-variant-firefox-settings =
    check "variant: no ${linuxHome} in programs.firefox profile settings" (!lib.hasInfix linuxHome (profileSettings "firefox")) "found in ${profileSettings "firefox"}";

  check-variant-wrapper-distribution =
    check "variant: librewolf wrapper MOZ_APP_DISTRIBUTION is under home.homeDirectory"
      (lwDist != "" && lib.hasPrefix "${varHm.home.homeDirectory}/" lwDist)
      "MOZ_APP_DISTRIBUTION=${lwDist}, home=${varHm.home.homeDirectory}";
  check-variant-wrapper-text = check "variant: librewolf wrapper script has no ${linuxHome}" (!lib.hasInfix linuxHome lwText) "wrapper: ${lwText}";
}
