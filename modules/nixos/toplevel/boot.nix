{ delib
, lib
, pkgs
, ...
}:
delib.module {
  name = "boot";

  nixos.always = {
    boot.plymouth.enable = true;
    boot.kernelParams = [ "quiet" "splash" ];

    boot.loader = {
      timeout = 30;
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

        # efiInstallAsRemovable only refreshes EFI/BOOT/BOOTX64.EFI, but a
        # firmware entry left from an earlier install can keep starting
        # EFI/NixOS-boot/grubx64.efi (nixos-laptop: Boot0000, first in the
        # boot order). Nothing updated that copy, so after the GRUB update in
        # the unstable switch the old program couldn't load the new modules:
        # "symbol ... not found" before the menu. Keep NixOS' own GRUB copies
        # identical to the core.efi grub-install just wrote. Never fails the
        # rebuild. See Documentation/troubleshooting/README.md, section 6.
        extraInstallCommands = ''
          fresh=/boot/grub/x86_64-efi/core.efi
          if [ -f "$fresh" ]; then
            for f in /boot/EFI/NixOS*/grubx64.efi; do
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
}
