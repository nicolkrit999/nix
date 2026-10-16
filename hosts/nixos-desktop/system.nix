{ delib
, ...
}:
delib.host {
  name = "nixos-desktop";

  nixos = {
    system.stateVersion = "25.11";
    time.hardwareClockInLocalTime = true;

    environment.persistence."/persist".directories = [
      "/var/lib/systemd/linger"
    ];

    imports = [
      ./hardware-configuration.nix

      # Host-specific sops secrets (common ones live in
      # users/krit/common/toplevel/sops-secrets.nix, enabled via default.nix)
      (
        { config, ... }:
        {
          sops.secrets."krit-local-password".neededForUsers = true;

          users.users.${config.myconfig.constants.user}.hashedPasswordFile = config.sops.secrets.krit-local-password.path;
          users.users.root.hashedPasswordFile = config.sops.secrets.krit-local-password.path;

          # GitHub PAT for nix
          nix.extraOptions = ''
            !include ${config.sops.secrets.github_fg_pat_token_nix.path}
          '';
        }
      )

      # Wire sops secrets to services
      ../../templates/krit/sops/service-wiring.nix
    ];

    # Host-specific sops config
    sops = {
      defaultSopsFile = ./nixos-desktop-secrets-sops.yaml;
      defaultSopsFormat = "yaml";
      age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    };

    # Desktop-specific hardware
    boot = {
      binfmt.emulatedSystems = [ "aarch64-linux" ];
      initrd.kernelModules = [ "amdgpu" ];
      # DP-3 = the in-case sensor panel (1024x600, powered off, Windows-only use).
      kernelParams = [ "video=DP-3:d" ];
    };
    hardware.graphics.enable = true;
  };
}
