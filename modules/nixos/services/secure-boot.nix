{ delib
, config
, inputs
, lib
, pkgs
, ...
}:
delib.module {
  name = "services.secure-boot";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      pkiBundle = strOption "/persist/var/lib/sbctl";
      configurationLimit = intOption 10;
    };

  nixos.always = _: {
    imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      # Same content lanzaboote writes for autoGenerateKeys: without it a manual sbctl
      # falls back to /var/lib/sbctl, which is tmpfs on an impermanence host.
      sbctlConfig = (pkgs.formats.yaml { }).generate "sbctl.conf" {
        keydir = "${cfg.pkiBundle}/keys";
        guid = "${cfg.pkiBundle}/GUID";
      };
    in
    {
      assertions = [
        {
          assertion = !config.boot.loader.grub.enable;
          message = "services.secure-boot: lanzaboote replaces the bootloader install hook, so boot.loader.grub.enable must be false (the shared boot module skips its GRUB block when this is on).";
        }
        {
          assertion = !(myconfig.services.impermanence.enable or false) || lib.hasPrefix "/persist/" cfg.pkiBundle;
          message = "services.secure-boot.pkiBundle (${cfg.pkiBundle}) must live under /persist/ when services.impermanence is enabled, otherwise the signing keys vanish on reboot.";
        }
      ];

      boot.loader.systemd-boot.enable = lib.mkForce false;

      # No autoGenerateKeys / autoEnrollKeys / measuredBoot: keys are created and enrolled
      # by hand with sbctl (see Documentation/usage/secure-boot/lanzaboote.md).
      boot.lanzaboote = {
        enable = true;
        inherit (cfg) pkiBundle configurationLimit;
      };

      environment.systemPackages = [ pkgs.sbctl ];
      environment.etc."sbctl/sbctl.conf".source = sbctlConfig;

      # Used directly (no bind mount, no environment.persistence): a live-ISO chroot that
      # only mounts /persist must still find the keys to run the lanzaboote install hook.
      # sbctl creates the directory 0755, so pre-create it root-only.
      systemd.tmpfiles.rules = [ "d ${cfg.pkiBundle} 0700 root root -" ];
    };
}
