let host = builtins.getEnv "HOST_UNDER_TEST"; in
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  cfg = flake.nixosConfigurations.${host}.config;
  my = cfg.myconfig;

  check = cond: detail: if cond then "ok" else "FAIL: ${detail}";
  has = x: xs: builtins.elem x xs;
  persist = cfg.environment.persistence."/persist";
  persistDirs = map (d: d.directory or d) persist.directories;
  isLaptop = host == "nixos-laptop";
  fs = cfg.fileSystems;
  btrfsFs = lib.filterAttrs (_: v: v.fsType == "btrfs") fs;
  failing = builtins.filter (a: !a.assertion) cfg.assertions;
  themes = builtins.filter (n: my.services.${n}.enable or false) [ "sddm-astronaut" "sddm-pixie" ];
  powerMgrs = builtins.filter (n: my.services.${n}.enable or false) [ "auto-cpufreq" "tlp" ];
  tsFw = cfg.networking.firewall;
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
        (lib.all (d: has d persistDirs) [ "/etc/ssh" "/var/lib/nixos" "/var/lib/tailscale" ])
        "persisted dirs missing one of /etc/ssh /var/lib/nixos /var/lib/tailscale";
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
      check-tailscale-autoconnect-wantedby = check
        (has "multi-user.target" cfg.systemd.services.tailscale-autoconnect.wantedBy)
        "tailscale-autoconnect not wantedBy multi-user.target";

      check-no-failing-assertions = check (failing == [ ])
        (builtins.toJSON (map (a: a.message) failing));
    };
  guard = v: let r = builtins.tryEval (builtins.deepSeq v v); in if r.success then r.value else "FAIL: eval error (option missing or throw)";
in
lib.mapAttrs (_: guard) checks
