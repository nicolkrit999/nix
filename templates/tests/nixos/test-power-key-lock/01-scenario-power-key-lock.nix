let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;
  lib = flake.inputs.nixpkgs.lib;

  nixosPaths = [
    (src + "/templates/tests/nixos/test-power-key-lock/shared/nixos-extra-x86_64")
    (src + "/modules/nixos/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants-nixos.nix")
    (src + "/modules/common/config/constants.nix")
    (src + "/modules/nixos/toplevel/hyprland.nix")
    (src + "/modules/nixos/toplevel/niri.nix")
    (src + "/modules/nixos/toplevel/mango.nix")
    (src + "/modules/nixos/programs/de-wm/niri/niri-main.nix")
    (src + "/modules/nixos/programs/de-wm/gnome/gnome-binds.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-kscreenlocker.nix")
    (src + "/modules/nixos/programs/de-wm/cosmic/cosmic-binds.nix")
    (src + "/modules/nixos/services/hypr/hypridle.nix")
    (src + "/modules/nixos/services/power/power-key-lock.nix")
  ];

  host = (denix.lib.configurations {
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
    paths = [ (src + "/templates/tests/nixos/test-power-key-lock/shared/host-power-key-lock.nix") ] ++ nixosPaths;
    exclude = [ ];
  }).power-key-host;

  twin = mods: (host.extendModules { modules = mods; }).config;
  force = lib.mkOverride 10;
  sessions = [ "hyprland" "niri" "mango" "gnome" "kde" "cosmic" ];
  only = s: lib.genAttrs sessions (n: { enable = force (n == s); });
  lockOn = { myconfig.services.powerKeyLock.enable = force true; };
  sessionOn = s: twin [{ myconfig.programs = only s; } lockOn];
  sessionDefault = s: twin [{ myconfig.programs = only s; }];
  lockOff = { myconfig.services.powerKeyLock.enable = force false; };
  sessionOff = s: twin [{ myconfig.programs = only s; } lockOff];

  none = host.config;
  hmOf = c: c.home-manager.users.krit;
  login = c: c.services.logind.settings.Login or { };
  powerKeys = c: lib.filterAttrs (n: _: lib.hasPrefix "HandlePowerKey" n) (login c);
  lockKeys = { HandlePowerKey = "lock"; HandlePowerKeyLongPress = "poweroff"; };

  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  show = builtins.toJSON;

  logindSet = c: chk (powerKeys c == lockKeys) "logind power keys ${show (powerKeys c)}";
  logindUnset = c: chk (powerKeys c == { }) "logind power keys ${show (powerKeys c)}";

  hypridleConf = c: (hmOf c).xdg.configFile."hypr/hypridle.conf".text or "";
  hasLockCmd = c: (hmOf c).services.hypridle.enable && lib.hasInfix "lock_cmd" (hypridleConf c);

  niriHandling = c: (hmOf c).programs.niri.settings.input.power-key-handling.enable;

  dconf = c: (hmOf c).dconf.settings;
  powerPlugin = c: (dconf c)."org/gnome/settings-daemon/plugins/power" or { };
  gnomeBinds = c: lib.filter (v: v ? binding) (lib.attrValues (dconf c));
  gnomePowerBind = c: lib.filter (b: b.binding == "XF86PowerOff") (gnomeBinds c);

  powerdevil = c: (hmOf c).programs.plasma.powerdevil;
  plasmaButton = c: lib.genAttrs [ "AC" "battery" "lowBattery" ] (p: (powerdevil c).${p}.powerButtonAction or null);
  plasmaAll = v: lib.genAttrs [ "AC" "battery" "lowBattery" ] (_: v);

  cosmicShortcuts = c: (hmOf c).wayland.desktopManager.cosmic.shortcuts or [ ];
  cosmicPowerBind = c: lib.filter (s: (s.key or "") == "XF86PowerOff") (cosmicShortcuts c);
  lockVariant = s: s.action.variant == "System" && map (v: v.variant) s.action.value == [ "LockScreen" ];
  failedAssertions = c: lib.filter (m: lib.hasInfix "programs.cosmic" m) (map (a: a.message) (lib.filter (a: !a.assertion) c.assertions));

  cosmicClash = lock: twin [
    { myconfig.programs = only "cosmic"; }
    { myconfig.programs.cosmic.disabledDefaults = force [ "XF86PowerOff" ]; }
    { myconfig.services.powerKeyLock.enable = force lock; }
  ];
  clashMsgs = c: lib.filter (m: lib.hasInfix "disabledDefaults" m) (failedAssertions c);
in
{
  results = {
    "option services.powerKeyLock.enable defaults to false" =
      chk (host.options.myconfig.services.powerKeyLock.enable.default == false && !none.myconfig.services.powerKeyLock.enable)
        "default ${show host.options.myconfig.services.powerKeyLock.enable.default}, host value ${show none.myconfig.services.powerKeyLock.enable}";

    "hyprland only: logind HandlePowerKey=lock, LongPress=poweroff" = logindSet (sessionOn "hyprland");
    "niri only: logind HandlePowerKey=lock, LongPress=poweroff" = logindSet (sessionOn "niri");
    "mango only: logind HandlePowerKey=lock, LongPress=poweroff" = logindSet (sessionOn "mango");
    "gnome only: logind HandlePowerKey=lock, LongPress=poweroff" = logindSet (sessionOn "gnome");
    "kde only: logind HandlePowerKey=lock, LongPress=poweroff" = logindSet (sessionOn "kde");
    "cosmic only: logind HandlePowerKey=lock, LongPress=poweroff" = logindSet (sessionOn "cosmic");
    "default (option off) with a session enabled: no HandlePowerKey settings" = logindUnset (sessionDefault "hyprland");
    "real hosts: laptop enables powerKeyLock, desktop does not" =
      let
        l = flake.nixosConfigurations.nixos-laptop.config.myconfig.services.powerKeyLock.enable;
        d = flake.nixosConfigurations.nixos-desktop.config.myconfig.services.powerKeyLock.enable;
      in
      chk (l == true && d == false) "laptop ${show l}, desktop ${show d}";
    "no session enabled: no HandlePowerKey settings" = logindUnset none;
    "option disabled (hyprland on): no HandlePowerKey settings" = logindUnset (sessionOff "hyprland");
    "option disabled (niri on): no HandlePowerKey settings" = logindUnset (sessionOff "niri");
    "option disabled (mango on): no HandlePowerKey settings" = logindUnset (sessionOff "mango");
    "option disabled (gnome on): no HandlePowerKey settings" = logindUnset (sessionOff "gnome");
    "option disabled (kde on): no HandlePowerKey settings" = logindUnset (sessionOff "kde");
    "option disabled (cosmic on): no HandlePowerKey settings" = logindUnset (sessionOff "cosmic");

    "hyprland: hypridle lock_cmd exists (reacts to the logind Lock signal)" =
      chk (hasLockCmd (sessionOn "hyprland")) "no hypridle lock_cmd";
    "niri: hypridle lock_cmd exists (reacts to the logind Lock signal)" =
      chk (hasLockCmd (sessionOn "niri")) "no hypridle lock_cmd";
    "mango: hypridle lock_cmd exists (reacts to the logind Lock signal)" =
      chk (hasLockCmd (sessionOn "mango")) "no hypridle lock_cmd";

    "niri on: compositor power-key handling disabled" =
      chk (niriHandling (sessionOn "niri") == false) "power-key-handling.enable ${show (niriHandling (sessionOn "niri"))}";
    "niri on, option off: compositor power-key handling stays true" =
      chk (niriHandling (sessionOff "niri") == true) "power-key-handling.enable ${show (niriHandling (sessionOff "niri"))}";

    "gnome on: power-button-action = nothing" =
      chk ((powerPlugin (sessionOn "gnome")).power-button-action or null == "nothing") "power plugin ${show (powerPlugin (sessionOn "gnome"))}";
    "gnome on: custom keybinding XF86PowerOff runs loginctl lock-session" =
      let b = gnomePowerBind (sessionOn "gnome"); in
      chk (builtins.length b == 1 && (builtins.head b).command == "loginctl lock-session") "bindings ${show b}";
    "gnome on, option off: no power-button-action and no XF86PowerOff binding" =
      chk (powerPlugin (sessionOff "gnome") == { } && gnomePowerBind (sessionOff "gnome") == [ ])
        "power plugin ${show (powerPlugin (sessionOff "gnome"))}, bindings ${show (gnomePowerBind (sessionOff "gnome"))}";
    "gnome on, option off: the other custom keybindings are still generated" =
      chk (builtins.length (gnomeBinds (sessionOff "gnome")) > 0 && builtins.length (gnomeBinds (sessionOn "gnome")) == builtins.length (gnomeBinds (sessionOff "gnome")) + 1)
        "binding counts on ${toString (builtins.length (gnomeBinds (sessionOn "gnome")))}, off ${toString (builtins.length (gnomeBinds (sessionOff "gnome")))}";

    "kde on: powerdevil powerButtonAction applied value 32 (lockScreen) on AC, battery, lowBattery" =
      chk (plasmaButton (sessionOn "kde") == plasmaAll 32) "powerdevil ${show (plasmaButton (sessionOn "kde"))}";
    "kde on, option off: no powerButtonAction set" =
      chk (plasmaButton (sessionOff "kde") == plasmaAll null) "powerdevil ${show (plasmaButton (sessionOff "kde"))}";

    "cosmic on: shortcut XF86PowerOff is System(LockScreen)" =
      let s = cosmicPowerBind (sessionOn "cosmic"); in
      chk (builtins.length s == 1 && lockVariant (builtins.head s)) "shortcuts ${show s}";
    "cosmic on, option off: no XF86PowerOff shortcut" =
      chk (cosmicPowerBind (sessionOff "cosmic") == [ ]) "shortcuts ${show (cosmicPowerBind (sessionOff "cosmic"))}";
    "cosmic on: no failed programs.cosmic assertion" =
      chk (failedAssertions (sessionOn "cosmic") == [ ]) "assertions ${show (failedAssertions (sessionOn "cosmic"))}";
    "cosmic: disabledDefaults = XF86PowerOff trips the clash assertion while the lock bind is on" =
      chk (builtins.length (clashMsgs (cosmicClash true)) == 1) "messages ${show (clashMsgs (cosmicClash true))}";
    "cosmic: the same disabledDefaults entry is fine when the option is off" =
      chk (clashMsgs (cosmicClash false) == [ ]) "messages ${show (clashMsgs (cosmicClash false))}";

    "gnome only: no hypridle lock_cmd (hypridle is for the three WMs)" =
      chk (!hasLockCmd (sessionOn "gnome")) "unexpected lock_cmd";
  };

  control = {
    "logindSet rejects an unset host" = chk (logindSet none != "ok") "logindSet passed with no session";
    "logindUnset rejects a host with the keys" = chk (logindUnset (sessionOn "hyprland") != "ok") "logindUnset passed on a locked host";
    "niri twin differs between option on and off" = chk (niriHandling (sessionOn "niri") != niriHandling (sessionOff "niri")) "twins identical";
    "gnome twin differs between option on and off" = chk (gnomePowerBind (sessionOn "gnome") != gnomePowerBind (sessionOff "gnome")) "twins identical";
    "kde twin differs between option on and off" = chk (plasmaButton (sessionOn "kde") != plasmaButton (sessionOff "kde")) "twins identical";
    "cosmic twin differs between option on and off" = chk (cosmicPowerBind (sessionOn "cosmic") != cosmicPowerBind (sessionOff "cosmic")) "twins identical";
    "lockVariant rejects a plain Spawn action" = chk (!lockVariant { action = { variant = "Spawn"; value = [ "x" ]; }; }) "accepted Spawn";
  };
}
