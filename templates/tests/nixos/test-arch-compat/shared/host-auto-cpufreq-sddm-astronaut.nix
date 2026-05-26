{ delib, ... }:
delib.host {
  name = "arch-compat-a";
  type = "desktop";
  homeManagerSystem = "aarch64-linux";

  myconfig = _: {
    constants = import ./base-constants.nix;

    # Window managers
    programs.hyprland.enable = true;
    programs.niri.enable = true;
    programs.mango.enable = true;
    programs.gnome.enable = true;
    programs.kde.enable = true;
    programs.cosmic.enable = true;

    # Custom shells: aarch64 assertion fires — expected, tests that the assertion path works.
    programs.caelestia = {
      enable = true;
      enableOnHyprland = true;
    };
    programs.noctalia = {
      enable = true;
      enableOnHyprland = true;
      enableOnNiri = true;
      enableOnMango = true;
    };

    # Waybars
    programs.waybar-hyprland.enable = true;
    programs.waybar-niri.enable = true;
    programs.waybar-mango.enable = true;

    # CLI programs that default to false
    programs.bat.enable = true;
    programs.eza.enable = true;
    programs.yazi.plugins.enable = true;
    programs.zoxide.enable = true;
    programs.npm.enable = true;
    programs.claude-code.enable = true;
    programs.comma.enable = true;
    # doom disabled: home.always still imports nix-doom-emacs-unstraightened homeModule
    # (aarch64-compat tested), but home.ifEnabled (doomDir = ./doomdir) requires the
    # source to be in the Nix store — only works in the full flake context, not here.
    programs.doom.enable = false;
    programs.nltchNur.enable = true;
    programs.statix.enable = true;
    programs.television.enable = true;
    programs.zen.browser.enable = true;
    programs.fzf.nix-search-tv.enable = true;

    # NixOS programs
    programs.cava.enable = true;
    programs.claude-desktop.enable = true;
    programs.concord.enable = true;
    programs.google-antigravity.enable = true;
    programs.nix-alien.enable = true;
    programs.nix-ld.enable = true;
    programs.swayosd.enable = true;
    programs.tgt.enable = true;
    programs.vicinae.enable = true;
    programs.walker.enable = true;

    # Services
    bluetooth.enable = true;
    services.audio.enable = true;
    services.autotrash.enable = true;
    programs.nix-topology.enable = true;
    services.swaync.enable = true;
    services.tailscale.enable = true;
    services.resolved.enable = true;
    services.snapshots.enable = true;
    services.impermanence.enable = true;

    # Power: variant A uses auto-cpufreq (tlp disabled)
    services.auto-cpufreq.enable = true;

    # Display manager: variant A uses sddm-astronaut (sddm-pixie disabled)
    services.sddm-astronaut.enable = true;

    # Specializations
    specializations.deep-focus.enable = true;
    specializations.guest.enable = true;
    specializations.safe-mode.enable = true;
    specializations.secure-travel.enable = true;

    # users/krit/common programs
    krit.programs.alacritty.enable = true;
    krit.programs.kitty.enable = true;
    krit.programs.direnv.enable = true;
    krit.programs.neovim.enable = true;
    krit.programs.ranger.enable = true;
    krit.programs.yazi.enable = true;
    krit.programs.chromium.enable = true;
    krit.programs.firefox.enable = true;
    krit.programs.librewolf.enable = true;
    krit.programs.zathura.enable = true;
    krit.programs.claude-code-wrappers.enable = true;
    krit.attic.enable = true;

    # users/krit/nixos programs & services
    krit.programs.dolphin.enable = true;
    krit.programs.helium.enable = true;
    krit.programs.pwas.enable = true;
    krit.services.logitech.enable = true;
    krit.services.nas.desktop-borg-backup.enable = true;
    krit.services.nas.laptop-borg-backup.enable = true;
    krit.services.nas.owncloud.enable = true;
    krit.services.nas.smb.enable = true;
    krit.services.nas.sshfs.enable = true;
    krit.specializations.entertainment.enable = true;
    krit.specializations.home.enable = true;
    krit.specializations.school.enable = true;
  };
}
