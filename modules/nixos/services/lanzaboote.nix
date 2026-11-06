{ delib
, config
, inputs
, lib
, pkgs
, ...
}:
let
  # Phase 3 of Documentation/usage/secure-boot/lanzaboote.md also needs `tpm-reenroll`
  # sealed to PCR 7 and the stale GRUB firmware entry removed by hand.
  validConsoleMode = mode: builtins.elem mode [ "keep" "auto" "max" ] || builtins.match "[0-9]+" mode != null;
in
delib.module {
  name = "services.lanzaboote";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      secureBoot = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Declares that the firmware enforces Secure Boot. It can never flip the BIOS
          setting; it only applies the matching hardening and assertions (requires `enable`,
          and initrd emergencyAccess must be off).
        '';
      };
      pkiBundle = strOption "/persist/var/lib/sbctl";
      configurationLimit = intOption 10;
      consoleMode = lib.mkOption {
        type = lib.types.str;
        default = "keep";
        description = ''
          systemd-boot console mode written to loader.conf: "keep" (firmware default),
          "auto", "max" or a non-negative integer string such as "5". Firmware mode
          numbers are hardware specific: in the systemd-boot menu press `r` to cycle
          through the modes, or edit `console-mode` in /boot/loader/loader.conf.
        '';
      };
    };

  nixos.always = { myconfig, ... }: {
    imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

    assertions = [
      {
        assertion = !myconfig.services.lanzaboote.secureBoot || myconfig.services.lanzaboote.enable;
        message = "services.lanzaboote.secureBoot declares that the firmware enforces Secure Boot, which needs services.lanzaboote.enable = true (the signed boot chain comes from lanzaboote).";
      }
    ];
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
          message = "services.lanzaboote: lanzaboote replaces the bootloader install hook, so boot.loader.grub.enable must be false (the shared boot module skips its GRUB block when this is on).";
        }
        {
          assertion = !(myconfig.services.impermanence.enable or false) || lib.hasPrefix "/persist/" cfg.pkiBundle;
          message = "services.lanzaboote.pkiBundle (${cfg.pkiBundle}) must live under /persist/ when services.impermanence is enabled, otherwise the signing keys vanish on reboot.";
        }
        {
          assertion = validConsoleMode cfg.consoleMode;
          message = "services.lanzaboote.consoleMode (\"${cfg.consoleMode}\") must be \"keep\", \"auto\", \"max\" or a non-negative integer string such as \"5\".";
        }
        {
          assertion = !cfg.secureBoot || !config.boot.initrd.systemd.emergencyAccess;
          message = "services.lanzaboote.secureBoot is true, but boot.initrd.systemd.emergencyAccess is enabled: an initrd root shell defeats Secure Boot. Turn emergencyAccess off for this host.";
        }
      ];

      boot.loader.systemd-boot.enable = lib.mkForce false;

      # No autoGenerateKeys / autoEnrollKeys / measuredBoot: keys are created and enrolled
      # by hand with sbctl (see Documentation/usage/secure-boot/lanzaboote.md).
      boot.lanzaboote = {
        enable = true;
        inherit (cfg) pkiBundle configurationLimit;
        # boot.loader.systemd-boot.consoleMode is an enum without integers; the settings
        # option merges this over its own defaults (timeout, editor, default).
        settings."console-mode" = lib.mkDefault cfg.consoleMode;
      };

      environment.systemPackages = [ pkgs.sbctl ];
      environment.etc."sbctl/sbctl.conf".source = sbctlConfig;

      # Used directly (no bind mount, no environment.persistence): a live-ISO chroot that
      # only mounts /persist must still find the keys to run the lanzaboote install hook.
      # sbctl creates the directory 0755, so pre-create it root-only.
      systemd.tmpfiles.rules = [ "d ${cfg.pkiBundle} 0700 root root -" ];
    };
}
