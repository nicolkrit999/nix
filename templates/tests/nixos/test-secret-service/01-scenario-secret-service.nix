let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  host = builtins.getEnv "HOST";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  sys = flake.nixosConfigurations.${host};
  baseCfg = sys.config;
  cfgs = { base = baseCfg; } // lib.mapAttrs (_: s: s.configuration.config or s.configuration) baseCfg.specialisation;

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

  checks = _cfgName: c:
    let
      hm = c.home-manager.users.krit;
      plasma = c.services.desktopManager.plasma6.enable;
      kwalletPkg = lib.any (n: lib.hasPrefix "kwallet-" n) (pkgNames c.services.dbus.packages);
      rc = ini (c.environment.etc."xdg/kwalletrc".text or "");
      rcBad = lib.filter (k: (rc.${k} or "<unset>") != wantRc.${k}) (lib.attrNames wantRc);
      stubText = n: hm.xdg.dataFile."dbus-1/services/${n}.service".text or "";
      stubOk = n: builtins.match ".*Name=${lib.escapeRegex n}\n.*Exec=[^\n]*/bin/false\n.*" (stubText n) != null || builtins.match ".*Name=${lib.escapeRegex n}\n.*Exec=[^\n]*/bin/false" (stubText n) != null;
      dbusPkgs = pkgNames c.services.dbus.packages;
      portalNames = pkgNames c.xdg.portal.extraPortals;
      hmPortalNames = pkgNames hm.xdg.portal.extraPortals;
      allPkgs = c.environment.systemPackages ++ hm.home.packages;
      browsers = lib.filter (p: builtins.match "(brave|chromium|google-chrome|vscode)-[0-9].*" (p.name or "") != null) allPkgs;
      wrapped = lib.filter (p: builtins.match "(claude-desktop|google-antigravity.*)(-[0-9].*)?" (p.name or "") != null) allPkgs;
      portalCfgs = lib.attrNames c.xdg.portal.config;
      chk = cond: msg: if cond then "ok" else msg;
    in
    {
      "gnome-keyring is enabled" = chk c.services.gnome.gnome-keyring.enable "services.gnome.gnome-keyring.enable is false";
      "gnome-keyring is the only org.freedesktop.secrets D-Bus package" =
        chk
          (lib.length (lib.filter (n: lib.hasPrefix "gnome-keyring-" n && !(has "portal" n)) (lib.unique dbusPkgs)) == 1
            && !(lib.any (n: builtins.match "(keepassxc|oo7|pass-secret|kwallet-secret|ksecret).*" n != null) dbusPkgs)
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
        chk (browsers != [ ] && lib.all carries browsers) "without the flag: ${toString (map (p: p.name) (lib.filter (p: !(carries p)) browsers))}";
      "FHS-wrapped Electron apps carry gnome-libsecret" =
        chk (lib.all carries wrapped) "without the flag: ${toString (map (p: p.name) (lib.filter (p: !(carries p)) wrapped))}";
      "HM chromium and helium are pinned when enabled" =
        chk
          ((!(hm.programs.chromium.enable or false) || (lib.elem flag (hm.programs.chromium.commandLineArgs or [ ]) || carries hm.programs.chromium.package))
            && (!(hm.programs.helium.enable or false) || lib.elem flag (hm.programs.helium.extraFlags or [ ])))
          "HM chromium or helium lacks the flag";
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
