let host = builtins.getEnv "HOST_UNDER_TEST"; in
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  sys = flake.nixosConfigurations.${host};
  cfg = sys.config;
  avahiTwin = on: (sys.extendModules { modules = [{ services.avahi.enable = lib.mkForce on; }]; }).config.services.resolved.settings.Resolve;
  my = cfg.myconfig;

  check = cond: detail: if cond then "ok" else "FAIL: ${detail}";
  has = x: xs: builtins.elem x xs;
  asList = v: if builtins.isList v then v else [ v ];
  persist = cfg.environment.persistence."/persist";
  persistDirs = map (d: d.directory or d) persist.directories;
  isLaptop = host == "nixos-laptop";
  fs = cfg.fileSystems;
  btrfsFs = lib.filterAttrs (_: v: v.fsType == "btrfs") fs;
  failing = builtins.filter (a: !a.assertion) cfg.assertions;
  themes = builtins.filter (n: my.services.${n}.enable or false) [ "sddm-astronaut" "sddm-pixie" ];
  powerMgrs = builtins.filter (n: my.services.${n}.enable or false) [ "auto-cpufreq" "tlp" ];
  tsFw = cfg.networking.firewall;
  hmUser = cfg.home-manager.users.${my.constants.user};
  tsFlags = cfg.services.tailscale.extraUpFlags ++ cfg.services.tailscale.extraSetFlags;
  checks =
    {
      check-hostname = check (cfg.networking.hostName == my.constants.hostname && my.constants.hostname == host)
        "networking.hostName=${cfg.networking.hostName} constants.hostname=${my.constants.hostname} host=${host}";
      check-user = check (my.constants.user == "krit") "constants.user=${my.constants.user}";
      check-emergency-access-snapshot = check (my.constants.emergencyAccess == true)
        "constants.emergencyAccess=${lib.boolToString my.constants.emergencyAccess} (both hosts set true on purpose)";
      check-emergency-access-wired = check (cfg.boot.initrd.systemd.emergencyAccess == my.constants.emergencyAccess)
        "boot.initrd.systemd.emergencyAccess does not follow constants.emergencyAccess";

      check-impermanence-enabled = check my.services.impermanence.enable "services.impermanence disabled";
      check-root-tmpfs = check (fs."/".fsType == "tmpfs") "/ fsType=${fs."/".fsType}";
      check-persist-needed-for-boot = check fs."/persist".neededForBoot "/persist not neededForBoot";
      check-varlog-needed-for-boot = check fs."/var/log".neededForBoot "/var/log not neededForBoot";
      check-persist-dirs = check
        (lib.all (d: has d persistDirs) [ "/etc/ssh" "/var/lib/nixos" "/var/lib/tailscale" "/var/lib/systemd/timesync" "/var/lib/NetworkManager" ])
        "persisted dirs missing one of /etc/ssh /var/lib/nixos /var/lib/tailscale /var/lib/systemd/timesync /var/lib/NetworkManager";
      check-borgmatic-state-persisted = check
        (!cfg.services.borgmatic.enable || has "/var/lib/borgmatic" persistDirs)
        "borgmatic is enabled but /var/lib/borgmatic is not persisted: the borg cache and security dir would be lost every boot";
      check-random-seed-not-persisted = check (!(has "/var/lib/systemd/random-seed" (map (f: f.file or f) persist.files)))
        "/var/lib/systemd/random-seed must not be persisted: systemd creates it before the persist bind unit runs, so a live switch fails with 'A file already exists' (exit 4)";
      check-resolved-no-global-domains = check (!(has "~." (asList (cfg.services.resolved.settings.Resolve.Domains or [ ]))))
        "services.resolved.settings.Resolve.Domains contains ~. (inert without global DNS=)";
      check-resolved-mdns-off-with-avahi = check
        ((avahiTwin true).MulticastDNS or null == "false" && (avahiTwin false).MulticastDNS or null != "false")
        "resolved MulticastDNS must be false exactly when avahi is enabled (checked on avahi on/off twins)";
      check-persist-machine-id = check (has "/etc/machine-id" (map (f: f.file or f) persist.files))
        "/etc/machine-id not persisted";

      check-luks-cryptroot =
        if !isLaptop then "ok"
        else
          check
            (btrfsFs != { } && lib.all (v: v.device == "/dev/mapper/cryptroot") (lib.attrValues btrfsFs)
              && cfg.boot.initrd.luks.devices ? cryptroot)
            "a btrfs mount is not on /dev/mapper/cryptroot or luks device cryptroot missing";
      check-desktop-no-luks =
        if isLaptop then "ok"
        else
          check (cfg.boot.initrd.luks.devices == { })
            "desktop has LUKS devices but emergencyAccess=true comment assumes none";

      check-sops-key-persisted = check
        (cfg.sops.age.sshKeyPaths != [ ] && lib.all (p: lib.hasPrefix "/persist/" p) cfg.sops.age.sshKeyPaths)
        "sops.age.sshKeyPaths=${builtins.toJSON cfg.sops.age.sshKeyPaths}";
      check-sops-key-matches-persisted-ssh = check
        (lib.all (p: has (lib.removePrefix "/persist" (builtins.dirOf p)) persistDirs) cfg.sops.age.sshKeyPaths)
        "sops host key dir is not a persisted directory";
      check-password-secret-for-users = check cfg.sops.secrets."krit-local-password".neededForUsers
        "krit-local-password not neededForUsers";

      check-immutable-users = check (!cfg.users.mutableUsers) "users.mutableUsers is true";
      check-password-files = check
        (cfg.users.users.krit.hashedPasswordFile == cfg.sops.secrets."krit-local-password".path
          && cfg.users.users.root.hashedPasswordFile == cfg.sops.secrets."krit-local-password".path)
        "krit/root hashedPasswordFile not the sops krit-local-password path";

      check-bootloader = check
        (cfg.boot.loader.grub.enable && !cfg.boot.loader.systemd-boot.enable
          && !cfg.boot.loader.efi.canTouchEfiVariables && cfg.boot.loader.grub.efiInstallAsRemovable
          && cfg.boot.loader.grub.device == "nodev")
        "grub/efi bootloader contract broken";

      check-nix-pat-include = check (lib.hasInfix "!include /run/secrets/github_fg_pat_token_nix" cfg.nix.extraOptions)
        "nix.extraOptions lacks the PAT !include";
      check-pat-secret-declared = check
        (cfg.sops.secrets ? github_fg_pat_token_nix
          && cfg.sops.secrets.github_fg_pat_token_nix.path == "/run/secrets/github_fg_pat_token_nix")
        "sops secret github_fg_pat_token_nix missing or not at /run/secrets/";

      check-one-sddm-theme = check (builtins.length themes == 1) "enabled sddm themes: ${builtins.toJSON themes}";
      check-power-exclusive = check (builtins.length powerMgrs <= 1) "enabled: ${builtins.toJSON powerMgrs}";

      check-tailscale-trusted = check (has "tailscale0" tsFw.trustedInterfaces) "tailscale0 not trusted";
      check-tailscale-reverse-path = check (tsFw.checkReversePath == "loose")
        "checkReversePath=${toString tsFw.checkReversePath}";
      check-tailscale-operator = check (has "--operator=${my.constants.user}" tsFlags)
        "tailscale flags lack --operator=<user>: ${builtins.toJSON tsFlags}";
      check-tailscale-authkey-sops = check
        (cfg.sops.secrets ? tailscale_key
          && cfg.services.tailscale.authKeyFile == cfg.sops.secrets.tailscale_key.path
          && (cfg.sops.secrets.tailscale_key.owner or null == "root"
          || (cfg.sops.secrets.tailscale_key.owner or null == null && cfg.sops.secrets.tailscale_key.uid == 0))
          && cfg.sops.secrets.tailscale_key.mode == "0400")
        "services.tailscale.authKeyFile is not the root-only (0400) sops secret tailscale_key";

      check-hm-use-global-pkgs-pinned = check (cfg.home-manager.useGlobalPkgs == false)
        "home-manager.useGlobalPkgs is not false (deliberate pin)";
      check-hm-use-user-packages = check (cfg.home-manager.useUserPackages == true)
        "home-manager.useUserPackages is not true";
      check-hm-plasma-manager-loaded = check (hmUser.programs ? plasma && hmUser.programs.plasma ? enable)
        "home-manager.users.${my.constants.user}.programs.plasma is not declared (plasma-manager not imported)";

      check-no-failing-assertions = check (failing == [ ])
        (builtins.toJSON (map (a: a.message) failing));
    };
  guard = v: let r = builtins.tryEval (builtins.deepSeq v v); in if r.success then r.value else "FAIL: eval error (option missing or throw)";
in
lib.mapAttrs (_: guard) checks
