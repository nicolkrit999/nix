let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  host = builtins.getEnv "HOST";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  sys = flake.nixosConfigurations.${host};
  baseCfg = sys.config;
  cfgs = { base = baseCfg; } // lib.mapAttrs (_: s: s.configuration) baseCfg.specialisation;

  flag = "--password-store=gnome-libsecret";
  has = lib.hasInfix;
  carries = p: lib.any (n: let v = p.drvAttrs.${n}; in builtins.isString v && has flag v) (builtins.attrNames p.drvAttrs);
  pamText = c: svc: (c.security.pam.services.${svc} or { text = ""; }).text;

  includes = text: lib.unique (lib.concatMap
    (l: let m = builtins.match "[a-z]+ (include|substack) ([^ ]+) .*" l; in if m == null then [ ] else [ (lib.elemAt m 1) ])
    (lib.splitString "\n" text));
  pamFull = c: svc: fuel:
    let t = pamText c svc; in
    if fuel == 0 then t else lib.concatStringsSep "\n" ([ t ] ++ map (s: pamFull c s (fuel - 1)) (includes t));

  ini = text:
    let
      step = acc: line:
        let l = lib.trim line; in
        if l == "" then acc
        else if lib.hasPrefix "[" l then acc // { sec = l; }
        else
          let kv = lib.splitString "=" l; in
          acc // { vals = acc.vals // { "${acc.sec}/${lib.head kv}" = lib.concatStringsSep "=" (lib.tail kv); }; };
    in
    (lib.foldl' step { sec = ""; vals = { }; } (lib.splitString "\n" text)).vals;

  wantRc = {
    "[Wallet]/First Use" = "false";
    "[Wallet]/Enabled" = "true";
    "[KSecretD]/Enabled" = "false";
    "[org.freedesktop.secrets]/apiEnabled" = "false";
    "[Migration]/MigrateTo3rdParty" = "false";
  };

  pkgNames = ps: map (p: p.name or "") ps;
  stubNames = [
    "org.kde.kwalletd"
    "org.kde.secretservicecompat"
    "org.freedesktop.impl.portal.desktop.kwallet"
  ];
  realNames = [ "org.kde.kwalletd6" "org.kde.kwalletd5" "org.freedesktop.secrets" ];
  secretRoute = v: lib.toList v == [ "gnome-keyring" ];

  checks = cfgName: c:
    let
      hm = c.home-manager.users.krit;
      plasma = c.services.desktopManager.plasma6.enable;
      kwalletPkg = lib.any (n: has "kwallet" n) (pkgNames c.services.dbus.packages);
      rc = ini (c.environment.etc."xdg/kwalletrc".text or "");
      rcBad = lib.filter (k: (rc.${k} or "<unset>") != wantRc.${k}) (lib.attrNames wantRc);
      stubText = n: hm.xdg.dataFile."dbus-1/services/${n}.service".text or "";
      stubOk = n: (hm.xdg.dataFile."dbus-1/services/${n}.service".enable or false) && (builtins.match ".*Name=${lib.escapeRegex n}\n.*Exec=[^\n]*/bin/false\n.*" (stubText n) != null || builtins.match ".*Name=${lib.escapeRegex n}\n.*Exec=[^\n]*/bin/false" (stubText n) != null);
      dbusPkgs = pkgNames c.services.dbus.packages;
      portalNames = pkgNames c.xdg.portal.extraPortals;
      hmPortalNames = pkgNames hm.xdg.portal.extraPortals;
      allPkgs = c.environment.systemPackages ++ hm.home.packages;
      byInfix = subs: lib.filter (p: !(has "-school" (p.name or "")) && lib.any (s: has s (p.name or "")) subs) allPkgs; # school launchers exec the pinned pkgs.brave/vscode
      browsers = byInfix [ "brave" "chromium" "google-chrome" "vscode" ];
      wrapped = byInfix [ "claude-desktop" "antigravity" ];
      portalCfgs = lib.attrNames c.xdg.portal.config;
      chk = cond: msg: if cond then "ok" else msg;

      portalsOf = ps: n: lib.filter (p: lib.hasPrefix n (p.name or "")) ps;
      patched = p: has "UseIn=" (p.drvAttrs.postFixup or "");
      unpatchedGtkKde = ps:
        let sel = portalsOf ps "xdg-desktop-portal-gtk" ++ portalsOf ps "xdg-desktop-portal-kde" ++ portalsOf ps "xdg-desktop-portal-gnome";
        in portalsOf ps "xdg-desktop-portal-gtk" != [ ] && portalsOf ps "xdg-desktop-portal-kde" != [ ] && !(lib.any patched sel);
      upperKeys = lib.filter (k: k != lib.toLower k) (lib.attrNames c.xdg.portal.config ++ lib.attrNames hm.xdg.portal.config);
      portalDiff = lib.filter (k: (hm.xdg.portal.config.${k} or null) != (c.xdg.portal.config.${k} or null))
        (lib.unique (lib.attrNames c.xdg.portal.config ++ lib.attrNames hm.xdg.portal.config));
      manifest = lib.findFirst (p: (p.name or "") == "gnome-keyring-portal-manifest") null c.xdg.portal.extraPortals;
      manifestBody =
        if manifest == null then ""
        else lib.head (lib.splitString "\nEOF" (lib.elemAt (lib.splitString "<<EOF\n" manifest.drvAttrs.buildCommand) 1));
      manifestLines = lib.splitString "\n" manifestBody;
      manifestKv = lib.listToAttrs (map (l: let kv = lib.splitString "=" l; in lib.nameValuePair (lib.head kv) (lib.concatStringsSep "=" (lib.tail kv)))
        (lib.filter (l: has "=" l) manifestLines));
      wmNames = { hyprland = "Hyprland"; mango = "mango"; niri = "niri"; kde = "KDE"; gnome = "GNOME"; cosmic = "COSMIC"; };
      enabledWms = lib.filterAttrs (n: _: c.myconfig.programs.${n}.enable or false) wmNames;
      useIn = lib.splitString ";" (manifestKv.UseIn or "");
      missingWms = lib.filter (w: !(lib.elem w useIn)) (lib.attrValues enabledWms);
      txt = e: if (e.text or null) == null then "" else e.text;
      sockNames = a: lib.filter (n: n == "SSH_AUTH_SOCK") (lib.attrNames a);
      sockSources = lib.filter (s: s.hit) [
        { n = "environment.variables"; hit = sockNames c.environment.variables != [ ]; }
        { n = "environment.sessionVariables"; hit = sockNames c.environment.sessionVariables != [ ]; }
        { n = "systemd.globalEnvironment"; hit = sockNames c.systemd.globalEnvironment != [ ]; }
        { n = "systemd.user.settings.Manager"; hit = has "SSH_AUTH_SOCK" (builtins.toJSON (c.systemd.user.settings.Manager or { })); }
        { n = "HM home.sessionVariables"; hit = sockNames hm.home.sessionVariables != [ ]; }
        { n = "HM systemd.user.sessionVariables"; hit = sockNames hm.systemd.user.sessionVariables != [ ]; }
      ] ++ map (n: { n = "HM file ${n}"; hit = true; }) (lib.filter
        (n: has "SSH_AUTH_SOCK" (txt (hm.xdg.configFile.${n} or { }) + txt (hm.xdg.dataFile.${n} or { })))
        (lib.unique (lib.attrNames hm.xdg.configFile ++ lib.attrNames hm.xdg.dataFile)))
      ++ map (n: { n = "HM home.file ${n}"; hit = true; }) (lib.filter
        (n: has "SSH_AUTH_SOCK" (txt hm.home.file.${n}))
        (lib.attrNames hm.home.file));
      sockAssigns = lib.length (lib.filter (l: has "export SSH_AUTH_SOCK=" l) (lib.splitString "\n" c.environment.extraInit));
      electronPkgs = byInfix [ "ungoogled-chromium" "vscode" "claude-desktop" "antigravity" "chromium" "brave" "google-chrome" ];
      portalKeysMissing = lib.filter (w: !(c.xdg.portal.config ? ${lib.toLower w})) (lib.attrValues enabledWms);
      samplePam = "auth include login # x (order 1)\nsession substack common-session # y\nauth optional pam_foo.so";
      sampleIni = ini "[A]\nk=v=w\n\n[B]\nk2=1";
      selfTest =
        carries { drvAttrs = { a = "x ${flag} y"; b = 1; }; }
        && !(carries { drvAttrs = { a = "x"; }; })
        && includes samplePam == [ "login" "common-session" ]
        && sampleIni == { "[A]/k" = "v=w"; "[B]/k2" = "1"; }
        && secretRoute [ "gnome-keyring" ] && !(secretRoute [ "gnome-keyring" "kwallet" ]) && !(secretRoute [ ]);
    in
    {
      "gnome-keyring is enabled" = chk c.services.gnome.gnome-keyring.enable "services.gnome.gnome-keyring.enable is false";
      "gnome-keyring is the only org.freedesktop.secrets D-Bus package" =
        chk
          (lib.length (lib.filter (n: lib.hasPrefix "gnome-keyring-" n && !(has "portal" n)) (lib.unique dbusPkgs)) == 1
            && !(lib.any (n: builtins.match "(keepassxc|oo7|pass-secret|kwallet-secret|ksecret).*" n != null || has "secret" n || has "bitwarden" n) dbusPkgs)
            && !(c.services.passSecretService.enable or false))
          "another Secret Service provider is on the bus: ${toString dbusPkgs}";
      "kwalletrc carries the intended keys" =
        chk (!(plasma || kwalletPkg) || (c.environment.etc ? "xdg/kwalletrc" && rcBad == [ ]))
          "kwalletrc missing or wrong keys: ${toString rcBad}";
      "ksecretd names are stubbed with Exec=false" =
        chk (lib.all stubOk stubNames) "unstubbed: ${toString (lib.filter (n: !(stubOk n)) stubNames)}";
      "kwalletd6/kwalletd5/fdo secrets names are not stubbed" =
        chk (lib.all (n: !(hm.xdg.dataFile ? "dbus-1/services/${n}.service")) realNames)
          "a name that must stay unmasked has a stub";
      "plasma-kwallet-pam unit masked and pam_kwallet_init hidden" =
        chk
          (!plasma || (c.systemd.user.services.plasma-kwallet-pam.enable == false
            && has "Hidden=true" (hm.xdg.configFile."autostart/pam_kwallet_init.desktop".text or "")))
          "KWallet PAM pieces still active under plasma6";
      "PAM login and sddm include pam_gnome_keyring" =
        chk (lib.all (s: has "pam_gnome_keyring" (pamFull c s 4)) [ "login" "sddm" ]) "pam_gnome_keyring missing from login or sddm";
      "PAM sddm-autologin starts the keyring when present" =
        chk (!(c.security.pam.services ? sddm-autologin) || has "pam_gnome_keyring" (pamFull c "sddm-autologin" 4)) "sddm-autologin lacks pam_gnome_keyring";
      "kwallet PAM is off everywhere" =
        chk (lib.all (s: !(c.security.pam.services.${s}.kwallet.enable or false) && !(has "pam_kwallet" (pamFull c s 4))) (lib.attrNames c.security.pam.services))
          "a PAM service enables or includes pam_kwallet";
      "one SSH agent: gcr-ssh-agent only" =
        chk
          (c.services.gnome.gcr-ssh-agent.enable
            && c.programs.gnupg.agent.enableSSHSupport == false
            && c.programs.ssh.startAgent == false
            && (hm.services.gpg-agent.enableSshSupport or false) == false
            && (hm.services.ssh-agent.enable or false) == false
            && has "$XDG_RUNTIME_DIR/gcr/ssh" c.environment.extraInit)
          "SSH agent set is not exactly gcr-ssh-agent";
      "Secret portal routes to gnome-keyring in system portal config" =
        chk (portalCfgs != [ ] && lib.all (k: secretRoute (c.xdg.portal.config.${k}."org.freedesktop.impl.portal.Secret" or [ ])) portalCfgs)
          "portal configs without Secret=gnome-keyring: ${toString (lib.filter (k: !(secretRoute (c.xdg.portal.config.${k}."org.freedesktop.impl.portal.Secret" or [ ]))) portalCfgs)}";
      "Secret portal routes to gnome-keyring in the HM portal config" =
        chk (hm.xdg.portal.config != { } && lib.all (k: secretRoute (hm.xdg.portal.config.${k}."org.freedesktop.impl.portal.Secret" or [ ])) (lib.attrNames hm.xdg.portal.config))
          "HM portal configs without Secret=gnome-keyring: ${toString (lib.filter (k: !(secretRoute (hm.xdg.portal.config.${k}."org.freedesktop.impl.portal.Secret" or [ ]))) (lib.attrNames hm.xdg.portal.config))}";
      "gnome-keyring.portal manifest reaches system and HM portal dirs" =
        chk (lib.elem "gnome-keyring-portal-manifest" portalNames && lib.elem "gnome-keyring-portal-manifest" hmPortalNames)
          "manifest-only gnome-keyring.portal missing from extraPortals";
      "Chromium/Electron browsers installed carry gnome-libsecret" =
        chk ((browsers != [ ] || cfgName != "base") && lib.all carries browsers) "without the flag: ${toString (map (p: p.name) (lib.filter (p: !(carries p)) browsers))}";
      "FHS-wrapped Electron apps carry gnome-libsecret" =
        chk (lib.all carries wrapped) "without the flag: ${toString (map (p: p.name) (lib.filter (p: !(carries p)) wrapped))}";
      "self-test: helpers accept good samples and reject bad ones" = chk selfTest "carries/includes/ini/secretRoute helper is broken";
      "portal config has an entry for every enabled WM" =
        chk (portalKeysMissing == [ ]) "xdg.portal.config lacks keys for: ${toString portalKeysMissing}";
      "HM chromium and helium are pinned when enabled" =
        chk
          ((!(hm.programs.chromium.enable or false) || (lib.elem flag (hm.programs.chromium.commandLineArgs or [ ]) || carries hm.programs.chromium.package))
            && (!(hm.programs.helium.enable or false) || lib.elem flag (hm.programs.helium.extraFlags or [ ])))
          "HM chromium or helium lacks the flag";
      "portal config top-level keys are lowercase" =
        chk (portalCfgs != [ ] && upperKeys == [ ]) "non-lowercase xdg.portal.config keys: ${toString upperKeys}";
      "HM portal config equals the system portal config" =
        chk (portalDiff == [ ]) "HM and system xdg.portal.config differ for: ${toString portalDiff}";
      "gtk, kde and gnome portals keep their stock UseIn (no permissive patch)" =
        chk (unpatchedGtkKde c.xdg.portal.extraPortals && unpatchedGtkKde hm.xdg.portal.extraPortals)
          "gtk/kde missing from extraPortals, or a gtk/kde/gnome portal carries the UseIn postFixup patch (it makes kde.portal the deprecated-fallback winner in non-KDE sessions)";
      "environment.pathsToLink has /share/xdg-desktop-portal" =
        chk (lib.elem "/share/xdg-desktop-portal" c.environment.pathsToLink) "/share/xdg-desktop-portal not in environment.pathsToLink";
      "gnome-keyring.portal manifest text is well-formed" =
        chk
          (manifest != null
            && lib.hasPrefix "[portal]" manifestBody
            && !(lib.any (l: lib.hasPrefix " " l || lib.hasPrefix "\t" l) manifestLines)
            && (manifestKv.DBusName or "") == "org.freedesktop.secrets"
            && (manifestKv.Interfaces or "") == "org.freedesktop.impl.portal.Secret")
          "manifest missing, indented, or wrong DBusName/Interfaces: ${builtins.toJSON manifestBody}";
      "gnome-keyring.portal UseIn lists every enabled WM" =
        chk (missingWms == [ ]) "UseIn lacks enabled WMs: ${toString missingWms} (enabled: ${toString (lib.attrValues enabledWms)})";
      "SSH_AUTH_SOCK has a single source (extraInit gcr fallback)" =
        chk (sockSources == [ ] && sockAssigns == 1)
          "extra SSH_AUTH_SOCK sources: ${toString (map (s: s.n) sockSources)}; extraInit assignments: ${toString sockAssigns}";
      "broader Chromium/Electron set carries gnome-libsecret" =
        chk (lib.all carries electronPkgs)
          "without the flag: ${toString (map (p: p.name) (lib.filter (p: !(carries p)) electronPkgs))}";
      "duplicate HM gnome-keyring unit is absent" =
        chk
          (!(hm.services.gnome-keyring.enable or false)
            && !(lib.any (n: has "gnome-keyring" n) (lib.attrNames hm.systemd.user.services))
            && !(c.myconfig.programs ? gnome-keyring))
          "HM gnome-keyring service or myconfig.programs.gnome-keyring present";
    };

  perCfg = lib.mapAttrs checks cfgs;
  names = lib.attrNames (checks "base" baseCfg);
  verdict = n:
    let bad = lib.filterAttrs (_: v: v != "ok") (lib.mapAttrs (_: r: r.${n}) perCfg);
    in if bad == { } then "ok" else "FAIL: " + lib.concatStringsSep "; " (lib.mapAttrsToList (k: v: "${k}: ${v}") bad);

  pinned = lib.genAttrs [ "brave" "chromium" "google-chrome" "vscode" "signal-desktop" "vesktop" "teams-for-linux" "proton-pass" "drawio" "xmind" "whatsapp-electron" "github-desktop" "insomnia" ] (n: carries sys.pkgs.${n});
  pinVerdict =
    let bad = lib.filter (n: !pinned.${n}) (lib.attrNames pinned);
    in if bad == [ ] then "ok" else "FAIL: no --password-store flag: ${toString bad}";
in
{
  report = lib.concatStringsSep "\n" (map (n: "${n}\t${verdict n}") names ++ [ "overlay pins every Chromium/Electron package\t${pinVerdict}" ]) + "\n";
  configs = lib.concatStringsSep " " (lib.attrNames cfgs);
}
