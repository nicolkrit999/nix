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

    # DP-3 = the in-case sensor panel (1024x600, powered off, Windows-only use).
    # NOT the JetKVM - that is on HDMI-A-1 (it presents an ASUS PA248QV EDID, see
    # the HDMI-A-1 mirror block in default.nix). The panel's HDMI-to-DP cable keeps
    # hotplug asserted while the dead panel serves no EDID ("connected", 0-byte EDID),
    # so amdgpu logs "No EDID found on connector: DP-3" on every boot, clean ones
    # included - this is harmless probe noise, not a fault. It is unused under
    # Linux, so the connector is disabled at DRM probe time to quiet that noise;
    # this is NOT the fix for the historical boot/reboot hangs. That wedge is
    # caused by the JetKVM on HDMI-A-1 (amdgpu Display Core can't blank its CRTC
    # on shutdown - "REG_WAIT timeout ... optc3_lock" - jetkvm/kvm#1140, no
    # kernel fix as of 2026-07); the mitigation for that lives in the
    # hyprland-jetkvm-teardown systemd user unit in home.nix.
    boot.kernelParams = [ "video=DP-3:d" ];


    # Desktop-specific packages
    environment.systemPackages = with pkgs; [
      libvdpau-va-gl # Allow VA-GL to be used as a VDPAU backend for hardware video acceleration on AMD GPUs
    ];
  };
}
