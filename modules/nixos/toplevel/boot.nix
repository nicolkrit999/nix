{ delib
, lib
, pkgs
, config
, ...
}:
delib.module {
  name = "boot";

  nixos.always =
    { myconfig, ... }:
    {
      boot = {
        plymouth.enable = true;
        kernelParams = [
          "panic=10"
          "pause_on_oops=300"
          "quiet"
        ];
        initrd.systemd = {
          enable = true;
          emergencyAccess = myconfig.constants.emergencyAccess;
        };
        crashDump = {
          enable = true;
          reservedMemory = "512M";
        };

        loader = {
          timeout = 30;
          # pin: nixos-host-invariants asserts the bootloader contract
          efi.canTouchEfiVariables = false;

          systemd-boot.enable = lib.mkForce false;

          grub = {
            enable = lib.mkForce true;
            device = "nodev";
            efiSupport = true;
            efiInstallAsRemovable = true;
            useOSProber = true;
            gfxmodeEfi = "3840x2160,2560x1440,1920x1080,1024x768,auto";
            gfxpayloadEfi = "text";
            configurationLimit = 10;
            extraEntries = ''
              menuentry "UEFI Firmware Settings" {
                fwsetup
              }
            '';

            # efiInstallAsRemovable skips EFI/NixOS*/grubx64.efi; keep it identical to the fresh
            # core.efi. Never fails the rebuild. See Documentation/troubleshooting/README.md, section 6.
            extraInstallCommands = ''
              fresh=${(builtins.head config.boot.loader.grub.mirroredBoots).path}/grub/${(pkgs.grub2.override { efiSupport = true; }).grubTarget}/core.efi
              if [ -f "$fresh" ]; then
                for f in ${config.boot.loader.efi.efiSysMountPoint}/EFI/NixOS*/grub${pkgs.stdenv.hostPlatform.efiArch}.efi; do
                  [ -f "$f" ] || continue
                  if ! ${pkgs.diffutils}/bin/cmp -s "$fresh" "$f"; then
                    if ${pkgs.coreutils}/bin/cp "$fresh" "$f"; then
                      echo "boot.nix: refreshed stale GRUB copy $f"
                    else
                      echo "boot.nix: WARNING: could not refresh stale GRUB copy $f" >&2
                    fi
                  fi
                done
              fi
            '';
          };
        };
      };
    };
}
