{ delib
, inputs
, pkgs
, ...
}:
let
  myUserName = "krit";
in
delib.host {
  name = "nixos-desktop";

  nixos = {
    system.stateVersion = "25.11";
    time.hardwareClockInLocalTime = true;
    services.logind.settings.Login.HandlePowerKey = "poweroff";

    environment.variables = { };

    # Configure host specific impermanence persist
    environment.persistence."/persist" = {
      directories = [
      ];
      files = [
      ];
    };

    imports = [
      inputs.nix-sops.nixosModules.sops
      ./hardware-configuration.nix

      # Host-specific sops secrets (common ones live in
      # users/krit/common/toplevel/sops-secrets.nix, enabled via default.nix)
      (
        { config, ... }:
        {
          sops.secrets."krit-local-password".neededForUsers = true;

          users.users.${myUserName}.hashedPasswordFile = config.sops.secrets.krit-local-password.path;
          users.users.root.hashedPasswordFile = config.sops.secrets.krit-local-password.path;
        }
      )

      # Wire sops secrets to services
      ../../templates/krit/sops/service-wiring.nix

      # Other config
      (
        { config, ... }:
        {
          i18n.defaultLocale = config.myconfig.constants.mainLocale;
        }
      )
    ];

    # Host-specific sops config
    sops.defaultSopsFile = ./nixos-desktop-secrets-sops.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    # GitHub PAT for nix
    nix.extraOptions = ''
      !include /run/secrets/github_fg_pat_token_nix
    '';

    # Desktop-specific hardware
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    boot.initrd.kernelModules = [ "amdgpu" ];
    hardware.graphics.enable = true;

    # DP-3 is connected to a JetKVM device. At boot the KVM presents no EDID, which
    # causes amdgpu to log "No EDID found on connector: DP-3" and cascade into DCN
    # failures that kill all display output. Injecting a firmware EDID prevents this.
    #
    # amdgpu is loaded inside the initrd (boot.initrd.kernelModules above), so the
    # firmware blob must also be present inside the initrd image - hardware.firmware
    # only populates /run/current-system on the root FS, which is mounted too late.
    # boot.initrd.extraFiles plants the file at lib/firmware/edid/1920x1080.bin
    # inside the initramfs so the kernel firmware loader can find it during initrd.
    boot.kernelParams = [ "drm.edid_firmware=DP-3:edid/1920x1080.bin" ];
    hardware.firmware = [ pkgs.edid-generator ];
    boot.initrd.extraFiles."lib/firmware/edid/1920x1080.bin".source =
      "${pkgs.edid-generator}/lib/firmware/edid/1920x1080.bin";


    # Desktop-specific packages
    environment.systemPackages = with pkgs; [
      libvdpau-va-gl # Allow VA-GL to be used as a VDPAU backend for hardware video acceleration on AMD GPUs
    ];
  };
}
