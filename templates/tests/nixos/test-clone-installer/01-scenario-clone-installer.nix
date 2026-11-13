let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  layout = import "${flakeRoot}/templates/installer/layout.nix";

  nixos = flake.nixosConfigurations;
  installerSystem = "x86_64-linux";

  allPairs = {
    desktop = { original = "nixos-desktop"; clone = "nixos-desktop-2"; };
    laptop = { original = "nixos-laptop"; clone = "nixos-laptop-2"; };
  };
  # promote.sh removes a host's "-2" entry: that host is "promoted" and is then checked on its
  # own (generic label layer), while the clone-vs-original checks only run for the open pairs.
  pairs = lib.filterAttrs (_: p: nixos ? ${p.clone}) allPairs;
  promoted = lib.filterAttrs (_: p: !(nixos ? ${p.clone})) allPairs;

  rootMounts = [ "/boot" "/persist" "/nix" "/home" "/var/log" ];

  tags = [
    "hostname"
    "constants-hostname"
    "constants"
    "system-stateversion"
    "home-stateversion"
    "sops-file"
    "sops-keys"
    "sops-secrets"
    "bootloader"
    "persist-flags"
    "label-layer"
    "no-uuid"
    "luks-device"
  ];

  problems = orig: clone: expectedName:
    let
      o = orig.config;
      c = clone.config;
      luks = o.boot.initrd.luks.devices != { };
      wantDev = mount:
        if mount == "/boot" then "/dev/disk/by-label/${layout.espLabel}"
        else if luks then "/dev/mapper/${layout.luksMapperName}"
        else "/dev/disk/by-label/${layout.btrfsLabel}";
      dev = cfg: mount: cfg.fileSystems.${mount}.device;
      boot = cfg: builtins.toJSON {
        lanza = cfg.boot.lanzaboote.enable or null;
        grub = cfg.boot.loader.grub.enable;
        efiVars = cfg.boot.loader.efi.canTouchEfiVariables;
        editor = cfg.boot.loader.systemd-boot.editor;
      };
    in
    lib.optional (c.networking.hostName != expectedName || c.networking.hostName == o.networking.hostName) "hostname"
    ++ lib.optional (c.myconfig.constants.hostname != o.myconfig.constants.hostname) "constants-hostname"
    ++ lib.optional (builtins.toJSON c.myconfig.constants != builtins.toJSON o.myconfig.constants) "constants"
    ++ lib.optional (c.system.stateVersion != o.system.stateVersion) "system-stateversion"
    ++ lib.optional (c.myconfig.constants.homeStateVersion != o.myconfig.constants.homeStateVersion) "home-stateversion"
    ++ lib.optional (toString c.sops.defaultSopsFile != toString o.sops.defaultSopsFile) "sops-file"
    ++ lib.optional (c.sops.age.sshKeyPaths != o.sops.age.sshKeyPaths) "sops-keys"
    ++ lib.optional (builtins.attrNames c.sops.secrets != builtins.attrNames o.sops.secrets) "sops-secrets"
    ++ lib.optional (boot c != boot o) "bootloader"
    ++ lib.optional
      (lib.any (m: c.fileSystems.${m}.neededForBoot != o.fileSystems.${m}.neededForBoot) [ "/persist" "/var/log" ])
      "persist-flags"
    ++ lib.optional (lib.any (m: dev c m != wantDev m) rootMounts) "label-layer"
    ++ lib.optional (lib.any (m: lib.hasInfix "by-uuid" (dev c m)) rootMounts) "no-uuid"
    ++ lib.optional
      ((c.boot.initrd.luks.devices != { }) != luks
      || (luks && c.boot.initrd.luks.devices.${layout.luksMapperName}.device != "/dev/disk/by-partlabel/${layout.luksPartLabel}"))
      "luks-device";

  expectNone = tag: ps:
    if builtins.elem tag ps then "FAIL: clone differs from its original (${tag})" else "ok";

  expectDetected = what: tag: ps:
    if builtins.elem tag ps then "ok" else "FAIL: mutation not detected: ${what} (expected tag ${tag}, got ${builtins.toJSON ps})";

  realChecks = lib.concatMapAttrs
    (pname: p:
      let ps = problems nixos.${p.original} nixos.${p.clone} p.clone; in
      lib.listToAttrs (map (t: lib.nameValuePair "clone-${pname}-${t}" (expectNone t ps)) tags))
    pairs;

  mutate = host: mod: host.extendModules { modules = [ mod ]; };
  force = lib.mkOverride 10;

  desktop = allPairs.desktop;
  laptop = allPairs.laptop;
  dClone = nixos.${desktop.clone};
  lClone = nixos.${laptop.clone};
  dProblems = m: problems nixos.${desktop.original} (mutate dClone m) desktop.clone;
  lProblems = m: problems nixos.${laptop.original} (mutate lClone m) laptop.clone;

  controlsDesktop = {
    "control-original-as-clone-desktop" =
      let ps = problems nixos.${desktop.original} nixos.${desktop.original} desktop.clone;
      in
      if builtins.elem "hostname" ps && builtins.elem "label-layer" ps && builtins.elem "no-uuid" ps then "ok"
      else "FAIL: the unmodified original passes as a clone: ${builtins.toJSON ps}";
    "control-mutant-hostname-unchanged" =
      expectDetected "clone keeps the original networking.hostName" "hostname"
        (dProblems { networking.hostName = force desktop.original; });
    "control-mutant-constants-hostname" =
      expectDetected "constants.hostname changed" "constants-hostname"
        (dProblems { myconfig.constants.hostname = force "other-host"; });
    "control-mutant-system-stateversion" =
      expectDetected "system.stateVersion bumped" "system-stateversion"
        (dProblems { system.stateVersion = force "99.11"; });
    "control-mutant-home-stateversion" =
      expectDetected "homeStateVersion bumped" "home-stateversion"
        (dProblems { myconfig.constants.homeStateVersion = force "99.11"; });
    "control-mutant-sops-file" =
      expectDetected "sops file of another host" "sops-file"
        (dProblems { sops.defaultSopsFile = force nixos.${laptop.original}.config.sops.defaultSopsFile; });
    "control-mutant-sops-keys" =
      expectDetected "sops ssh key path changed" "sops-keys"
        (dProblems { sops.age.sshKeyPaths = force [ "/etc/ssh/other_key" ]; });
    "control-mutant-sops-secrets" =
      expectDetected "extra sops secret" "sops-secrets"
        (dProblems { sops.secrets."probe-extra-secret" = { }; });
    "control-mutant-persist-flags" =
      expectDetected "/persist no longer neededForBoot" "persist-flags"
        (dProblems { fileSystems."/persist".neededForBoot = force false; });
    "control-mutant-uuid-boot" =
      expectDetected "/boot by-uuid" "no-uuid"
        (dProblems { fileSystems."/boot".device = force "/dev/disk/by-uuid/0000-0000"; });
    "control-mutant-label-layer" =
      expectDetected "/boot on a foreign label" "label-layer"
        (dProblems { fileSystems."/boot".device = force "/dev/disk/by-label/OTHER"; });
    "control-mutant-editor" =
      expectDetected "boot menu editor switched on in the clone" "bootloader"
        (dProblems { boot.loader.systemd-boot.editor = force true; });
    "control-mutant-bootloader" =
      expectDetected "bootloader flipped" "bootloader"
        (dProblems { boot.loader.efi.canTouchEfiVariables = force (!nixos.${desktop.original}.config.boot.loader.efi.canTouchEfiVariables); });
  };

  controlsLaptop = {
    "control-original-as-clone-laptop" =
      let ps = problems nixos.${laptop.original} nixos.${laptop.original} laptop.clone;
      in
      if builtins.elem "hostname" ps && builtins.elem "luks-device" ps && builtins.elem "no-uuid" ps then "ok"
      else "FAIL: the unmodified original passes as a clone: ${builtins.toJSON ps}";
    "control-mutant-luks-device" =
      expectDetected "LUKS device by-uuid" "luks-device"
        (lProblems { boot.initrd.luks.devices.${layout.luksMapperName}.device = force "/dev/disk/by-uuid/0000"; });
  };

  installerNameLike = n: lib.hasInfix "installer" n || builtins.elem "iso" (lib.splitString "-" n);
  exposesIso = host: host.config.system.build ? isoImage;
  pkgs = flake.packages or { };
  apps = flake.apps or { };
  names = a: builtins.attrNames a;
  onlyInstallerSystem = a: names a == [ installerSystem ];
  isApp = a: (a.type or null) == "app" && lib.isString (a.program or null);

  isoProbe = lib.nixosSystem {
    modules = [{ nixpkgs.hostPlatform = installerSystem; system.build.isoImage = "probe"; }];
  };

  outputs = {
    "outputs-packages-x86_64-linux" =
      let p = pkgs.${installerSystem} or { };
      in
      if lib.all (n: p ? ${n} && lib.isDerivation p.${n}) [ "installer" "make-bundle" "installer-iso" ] then "ok"
      else "FAIL: packages.${installerSystem} lacks installer / make-bundle / installer-iso (has ${builtins.toJSON (names p)})";
    "outputs-apps-x86_64-linux" =
      let a = apps.${installerSystem} or { };
      in
      if lib.all (n: a ? ${n} && isApp a.${n}) [ "install" "make-bundle" ] then "ok"
      else "FAIL: apps.${installerSystem} lacks install / make-bundle (has ${builtins.toJSON (names a)})";
    "outputs-iso-not-a-nixos-configuration" =
      let
        byName = lib.filter installerNameLike (names nixos);
        byImage = lib.filter (n: exposesIso nixos.${n}) (names nixos);
      in
      if byName == [ ] && byImage == [ ] then "ok"
      else "FAIL: installer ISO leaked into nixosConfigurations: names ${builtins.toJSON byName}, isoImage ${builtins.toJSON byImage}";
    "outputs-iso-not-a-home-or-darwin-config" =
      let
        hits = lib.filter installerNameLike (names flake.homeConfigurations ++ names flake.darwinConfigurations);
        cloneHits = lib.filter (n: builtins.elem n [ desktop.clone laptop.clone ]) (names flake.darwinConfigurations);
      in
      if hits == [ ] && cloneHits == [ ] then "ok"
      else "FAIL: installer or clone host in homeConfigurations/darwinConfigurations: ${builtins.toJSON (hits ++ cloneHits)}";
    "outputs-installer-linux-x86_64-only" =
      if onlyInstallerSystem pkgs && onlyInstallerSystem apps then "ok"
      else "FAIL: packages/apps systems are ${builtins.toJSON (names pkgs)} / ${builtins.toJSON (names apps)}, expected only ${installerSystem}";
    "control-name-predicate-catches-iso" =
      if installerNameLike "installer-iso" && installerNameLike "clone-iso" && !installerNameLike "nixos-desktop-2" then "ok"
      else "FAIL: installerNameLike does not separate installer names from host names";
    "control-isoimage-predicate-catches-iso" =
      if exposesIso isoProbe && !exposesIso nixos.${desktop.original} then "ok"
      else "FAIL: exposesIso cannot tell an ISO system from a host";
    "control-system-predicate-catches-darwin" =
      if !onlyInstallerSystem { x86_64-linux = 1; aarch64-darwin = 1; } && !onlyInstallerSystem { } && onlyInstallerSystem { x86_64-linux = 1; } then "ok"
      else "FAIL: onlyInstallerSystem accepts a darwin system or rejects the intended one";
    "control-app-predicate" =
      if isApp { type = "app"; program = "/x"; } && !isApp { type = "derivation"; } && !isApp { } then "ok"
      else "FAIL: isApp accepts a non-app";
  };

  existence = lib.concatMapAttrs
    (pname: p: {
      "clone-${pname}-exists" =
        if nixos ? ${p.original} && nixos ? ${p.clone} then "ok"
        else "FAIL: nixosConfigurations lacks ${p.original} or ${p.clone}";
    })
    pairs
  // lib.concatMapAttrs
    (pname: p: {
      "promoted-${pname}-original-exists" =
        if nixos ? ${p.original} then "ok"
        else "FAIL: ${p.clone} was promoted but nixosConfigurations lacks ${p.original}";
    })
    promoted;

  editorOff = host:
    let c = nixos.${host}.config;
    in
    if !(c.boot.lanzaboote.enable or false) || !c.boot.loader.systemd-boot.editor then "ok"
    else "FAIL: ${host} is a lanzaboote host but boot.loader.systemd-boot.editor is on (kernel command line editable at boot)";
  editorChecks = lib.concatMapAttrs
    (pname: p: {
      "editor-off-${pname}-original" = editorOff p.original;
    })
    allPairs
  // lib.concatMapAttrs
    (pname: p: {
      "editor-off-${pname}-clone" = editorOff p.clone;
    })
    pairs;

  promotedChecks = lib.concatMapAttrs
    (pname: p:
      let
        c = nixos.${p.original}.config;
        luks = c.boot.initrd.luks.devices != { };
        devs = map (m: c.fileSystems.${m}.device) rootMounts;
        wantBtrfs = if luks then "/dev/mapper/${layout.luksMapperName}" else "/dev/disk/by-label/${layout.btrfsLabel}";
      in
      {
        "promoted-${pname}-boot-by-label" =
          if c.fileSystems."/boot".device == "/dev/disk/by-label/${layout.espLabel}" then "ok"
          else "FAIL: promoted ${p.original} /boot is ${c.fileSystems."/boot".device}, not the generic by-label layer";
        "promoted-${pname}-no-uuid" =
          if lib.any (lib.hasInfix "by-uuid") devs then "FAIL: promoted ${p.original} still has a by-uuid root mount"
          else "ok";
        "promoted-${pname}-btrfs-device" =
          if lib.all (m: c.fileSystems.${m}.device == wantBtrfs) (lib.remove "/boot" rootMounts) then "ok"
          else "FAIL: promoted ${p.original} btrfs mounts are not on ${wantBtrfs}";
      })
    promoted;
in
existence // realChecks // promotedChecks // editorChecks
// lib.optionalAttrs (pairs ? desktop) controlsDesktop
// lib.optionalAttrs (pairs ? laptop) controlsLaptop
  // outputs
