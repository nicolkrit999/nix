{ delib, ... }:
delib.host {
  name = "arch-compat-a";
  type = "desktop";
  homeManagerSystem = "aarch64-linux";

  myconfig = _: {
    constants = import ./base-constants.nix;

    # Window managers
    programs = {
      hyprland.enable = true;
      niri.enable = true;
      mango.enable = true;
      gnome.enable = true;
      kde.enable = true;
      cosmic.enable = true;

      # Custom shells: enabled on purpose; shellsInertOnAarch64 asserts they are no-ops on aarch64.
      caelestia = {
        enable = true;
        enableOnHyprland = true;
      };
      noctalia = {
        enable = true;
        enableOnHyprland = true;
        enableOnNiri = true;
        enableOnMango = true;
      };

      # Waybars
      waybar-hyprland.enable = true;
      waybar-niri.enable = true;
      waybar-mango.enable = true;

      # CLI programs that default to false
      bat.enable = true;
      eza.enable = true;
      yazi.plugins.enable = true;
      zoxide.enable = true;
      npm.enable = true;
      claude-code.enable = true;
      codex.enable = true;
      comma.enable = true;
      # doom disabled: home.always still imports nix-doom-emacs-unstraightened homeModule
      # (aarch64-compat tested), but home.ifEnabled (doomDir = ./doomdir) requires the
      # source to be in the Nix store - only works in the full flake context, not here.
      doom.enable = false;
      nltchNur.enable = true;
      agent-reach = {
        enable = true;
        browserChannels = true;
      };
      headroom.enable = true;
      herdr.enable = true;
      statix.enable = true;
      television.enable = true;
      zen.browser.enable = true;
      fzf.nix-search-tv.enable = true;

      # NixOS programs
      cava.enable = true;
      claude-desktop.enable = true;
      concord.enable = true;
      google-antigravity.enable = true;
      nix-alien.enable = true;
      nix-ld.enable = true;
      swayosd.enable = true;
      tgt.enable = true;
      vicinae.enable = true;
      walker.enable = true;
    };

    # Services
    bluetooth.enable = true;
    services = {
      audio.enable = true;
      autotrash.enable = true;
      swaync.enable = true;
      tailscale.enable = true;
      resolved.enable = true;
      snapshots.enable = true;
      impermanence.enable = true;

      # Power: variant A uses auto-cpufreq (tlp disabled)
      auto-cpufreq.enable = true;
      thermald.enable = true;

      # Display manager: variant A uses sddm-astronaut (sddm-pixie disabled)
      sddm-astronaut.enable = true;
    };

    # Specializations
    specializations = {
      deep-focus.enable = true;
      guest.enable = true;
      safe-mode.enable = true;
      secure-travel.enable = true;
    };

    # users/krit/common programs
    krit = {
      programs = {
        alacritty.enable = true;
        kitty.enable = true;
        direnv.enable = true;
        neovim.enable = true;
        ranger.enable = true;
        yazi.enable = true;
        chromium.enable = true;
        firefox.enable = true;
        librewolf.enable = true;
        zathura.enable = true;
        claude-code-wrappers.enable = true;

        # users/krit/nixos programs
        dolphin.enable = true;
        helium.enable = true;
        pwas.enable = true;
      };
      services = {
        logitech.enable = true;
        nas = {
          desktop-borg-backup.enable = true;
          laptop-borg-backup.enable = true;
          opencloud-mount.enable = true;
          smb.enable = true;
          sshfs.enable = true;
        };
      };
      specializations = {
        entertainment.enable = true;
        home.enable = true;
        school.enable = true;
      };
    };
    attic.enable = true;
  };
}
