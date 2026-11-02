---
name: project_tmpfs_root_home_not_needed_for_boot
description: tmpfs-root hosts with /home not neededForBoot give NEW users a root:root 0755 home (activation runs in initrd before @home mounts); HM fails "Could not find suitable profile directory", Hyprland SIGSEGV, Plasma empty
metadata:
  type: project
---

Both hosts have `/` on tmpfs and `/home` as a btrfs subvol. NixOS activation (incl. update-users-groups `createHome` chown/chmod) runs in the systemd initrd (`initrd-nixos-activation-start`) against /sysroot. If `/home` is not `neededForBoot`, the user's home is created on the tmpfs and then shadowed when stage 2 mounts @home (`home.mount: Directory /home to mount over is not empty`). Existing users (krit) never notice because their dir already exists on @home; a NEW user (krit-school, 2026-11-02) gets a dir created as root:root 0755 by whatever touches it first (automount mountpoints under ~/opencloud, root school-claude-sync).

Symptoms seen: `home-manager-krit\x2dschool.service` fails with "Could not find suitable profile directory" (its `nix-env -q` cannot create ~/.local/state/nix/profiles); Hyprland 0.56 SIGSEGV after "Couldn't create config home directory (Permission denied)"; Plasma starts with no config/keybinds, kwin/kded "Couldn't create ~/.cache".

Fix applied: `fileSystems."/home".neededForBoot = true;` in hosts/nixos-{laptop,desktop}/system.nix (hardware-configuration.nix is generated, not edited). The activation then re-chowns the existing root-owned home on next boot.

**How to apply:** any "new user, nothing works, Permission denied in $HOME" on these hosts: `ls -lan /home` first (metadata readable without sudo), then grep the boot for `mount over is not empty`. Note the journal unit name needs the `\x2d` escape (`-u 'home-manager-krit\x2dschool.service'`), plain `-u home-manager-krit-school.service` returns no entries.
