# Arch-compat scenario B: all modules + tlp + sddm-pixie.
# Returns an attrset of home.activationPackage derivations (one per batch),
# suitable for `nix build --dry-run --file this.nix --attr <name>`.
let
  flake = builtins.getFlake "path:/home/krit/nix";
  denix = flake.inputs.denix;

  nixosPaths = [
    /home/krit/nix/templates/tests/nixos/test-arch-compat/shared/nixos-extra-aarch64

    /home/krit/nix/modules/common/toplevel/home-manager.nix
    /home/krit/nix/modules/nixos/config/constants-nixos.nix
    /home/krit/nix/modules/nixos/toplevel/nix-nixos.nix
    /home/krit/nix/modules/common/themes/catppuccin.nix
    /home/krit/nix/modules/nixos/toplevel/common-configuration-nixos.nix

    /home/krit/nix/modules/nixos/toplevel/hyprland.nix
    /home/krit/nix/modules/nixos/toplevel/niri.nix
    /home/krit/nix/modules/nixos/toplevel/mango.nix
    /home/krit/nix/modules/nixos/toplevel/gnome.nix
    /home/krit/nix/modules/nixos/toplevel/kde.nix
    /home/krit/nix/modules/nixos/toplevel/cosmic.nix

    /home/krit/nix/modules/nixos/programs/de-wm/hyprland/hyprland-main.nix
    /home/krit/nix/modules/nixos/programs/de-wm/hyprland/hyprland-binds.nix
    /home/krit/nix/modules/nixos/programs/de-wm/hyprland/hyprland-hyprpaper.nix
    /home/krit/nix/modules/nixos/programs/de-wm/niri/niri-main.nix
    /home/krit/nix/modules/nixos/programs/de-wm/niri/niri-binds.nix
    /home/krit/nix/modules/nixos/programs/de-wm/mango/mango-main.nix
    /home/krit/nix/modules/nixos/programs/de-wm/mango/mango-binds.nix
    /home/krit/nix/modules/nixos/programs/de-wm/gnome/gnome-main.nix
    /home/krit/nix/modules/nixos/programs/de-wm/gnome/gnome-binds.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-main.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-binds.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-desktop.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-files.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-inputs.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-krunner.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-kscreenlocker.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-panels.nix
    /home/krit/nix/modules/nixos/programs/de-wm/cosmic/cosmic-main.nix

    /home/krit/nix/modules/nixos/programs/shells/caelestia-main.nix
    /home/krit/nix/modules/nixos/programs/shells/noctalia-main.nix

    /home/krit/nix/modules/nixos/programs/waybar/hyprland/waybar-hyprland.nix
    /home/krit/nix/modules/nixos/programs/waybar/niri/waybar-niri.nix
    /home/krit/nix/modules/nixos/programs/waybar/mango/waybar-mango.nix

    /home/krit/nix/modules/common/programs/shells/bash.nix
    /home/krit/nix/modules/common/programs/shells/fish.nix
    /home/krit/nix/modules/common/programs/shells/zsh.nix
    /home/krit/nix/modules/common/programs/shells/shell-aliases.nix
    /home/krit/nix/modules/common/programs/shells/starship.nix
    /home/krit/nix/modules/common/programs/shells/fzf.nix
    /home/krit/nix/modules/common/programs/shells/lazygit.nix
    /home/krit/nix/modules/common/programs/shells/tmux.nix
    /home/krit/nix/modules/common/programs/shells/bat.nix
    /home/krit/nix/modules/common/programs/shells/eza.nix
    /home/krit/nix/modules/common/programs/shells/git.nix
    /home/krit/nix/modules/common/programs/shells/npm.nix
    /home/krit/nix/modules/common/programs/shells/yazi-plugins.nix
    /home/krit/nix/modules/common/programs/shells/zoxide.nix
    /home/krit/nix/modules/common/programs/shells/nix-search-tv/nst-home.nix
    /home/krit/nix/modules/common/programs/claude-code.nix
    /home/krit/nix/modules/common/programs/comma.nix
    /home/krit/nix/modules/common/programs/doom/doom-main.nix
    /home/krit/nix/modules/common/programs/doom/doom-tree-sitter.nix
    /home/krit/nix/modules/common/programs/nltch-nur.nix
    /home/krit/nix/modules/common/programs/statix.nix
    /home/krit/nix/modules/common/programs/television.nix
    /home/krit/nix/modules/common/programs/zen-browser.nix
    /home/krit/nix/modules/common/services/tailscale.nix
    /home/krit/nix/modules/common/toplevel/cachix.nix
    /home/krit/nix/modules/common/toplevel/nh.nix
    /home/krit/nix/modules/common/toplevel/nix-sweeps.nix

    /home/krit/nix/modules/nixos/programs/cava.nix
    /home/krit/nix/modules/nixos/programs/claude-desktop.nix
    /home/krit/nix/modules/nixos/programs/concord.nix
    /home/krit/nix/modules/nixos/programs/google-antigravity.nix
    /home/krit/nix/modules/nixos/programs/nix-alien.nix
    /home/krit/nix/modules/nixos/programs/nix-ld.nix
    /home/krit/nix/modules/nixos/programs/nix-topology.nix
    /home/krit/nix/modules/nixos/programs/swayosd.nix
    /home/krit/nix/modules/nixos/programs/tgt.nix
    /home/krit/nix/modules/nixos/programs/vicinae.nix
    /home/krit/nix/modules/nixos/programs/walker.nix

    /home/krit/nix/modules/nixos/services/audio.nix
    /home/krit/nix/modules/nixos/services/autotrash.nix
    /home/krit/nix/modules/nixos/services/hypr/hypridle.nix
    /home/krit/nix/modules/nixos/services/hypr/hyprlock.nix
    /home/krit/nix/modules/nixos/services/impermanence.nix
    /home/krit/nix/modules/nixos/services/power/auto-cpufreq.nix
    /home/krit/nix/modules/nixos/services/power/tlp.nix
    /home/krit/nix/modules/nixos/services/resolved.nix
    /home/krit/nix/modules/nixos/services/sddm/sddm-astronaut.nix
    /home/krit/nix/modules/nixos/services/sddm/sddm-pixie.nix
    /home/krit/nix/modules/nixos/services/snapshots.nix
    /home/krit/nix/modules/nixos/services/swaync.nix

    /home/krit/nix/modules/nixos/toplevel/bluetooth.nix
    /home/krit/nix/modules/nixos/toplevel/zram.nix
    /home/krit/nix/modules/nixos/toplevel/net.nix
    /home/krit/nix/modules/nixos/toplevel/qt.nix
    /home/krit/nix/modules/nixos/toplevel/xdg-portal.nix

    /home/krit/nix/modules/nixos/specializations/deep-focus.nix
    /home/krit/nix/modules/nixos/specializations/guest.nix
    /home/krit/nix/modules/nixos/specializations/safe-mode.nix
    /home/krit/nix/modules/nixos/specializations/secure-travel.nix

    # users/krit/common — cross-platform user modules
    /home/krit/nix/users/krit/common/programs/claude-code-wrappers.nix
    /home/krit/nix/users/krit/common/programs/cli-programs/direnv.nix
    /home/krit/nix/users/krit/common/programs/cli-programs/neovim.nix
    /home/krit/nix/users/krit/common/programs/file-managers/ranger.nix
    /home/krit/nix/users/krit/common/programs/file-managers/yazi/init-lua.nix
    /home/krit/nix/users/krit/common/programs/file-managers/yazi/yazi-keymap.nix
    /home/krit/nix/users/krit/common/programs/file-managers/yazi/yazi.nix
    /home/krit/nix/users/krit/common/programs/file-managers/yazi/yazi-theme.nix
    /home/krit/nix/users/krit/common/programs/gui-programs/chromium.nix
    /home/krit/nix/users/krit/common/programs/gui-programs/firefox.nix
    /home/krit/nix/users/krit/common/programs/gui-programs/librewolf/librewolf-common.nix
    # profiles/librewolf-profile-{default,privacy}.nix excluded: they are { addons, ... } helper
    # functions called by librewolf-common.nix, not standalone denix modules.
    /home/krit/nix/users/krit/common/programs/gui-programs/zathura.nix
    /home/krit/nix/users/krit/common/programs/gui-programs/zen-browser/extensions.nix
    /home/krit/nix/users/krit/common/programs/gui-programs/zen-browser/keyboard.nix
    /home/krit/nix/users/krit/common/programs/gui-programs/zen-browser/mods.nix
    /home/krit/nix/users/krit/common/programs/gui-programs/zen-browser/pins.nix
    /home/krit/nix/users/krit/common/programs/gui-programs/zen-browser/search.nix
    /home/krit/nix/users/krit/common/programs/gui-programs/zen-browser/settings.nix
    /home/krit/nix/users/krit/common/programs/terminal-emulators/alacritty.nix
    /home/krit/nix/users/krit/common/programs/terminal-emulators/kitty.nix
    /home/krit/nix/users/krit/common/toplevel/attic.nix

    # users/krit/nixos — NixOS-specific user modules (ext-dotfiles excluded: pure symlinks, no arch risk)
    /home/krit/nix/users/krit/nixos/common/home/home-base.nix
    /home/krit/nix/users/krit/nixos/common/system/default-user.nix
    /home/krit/nix/users/krit/nixos/common/system/git-ssh-signing.nix
    /home/krit/nix/users/krit/nixos/common/system/ssh-config.nix
    /home/krit/nix/users/krit/nixos/common/system/swiss-locale.nix
    /home/krit/nix/users/krit/nixos/common/system/virtualisation.nix
    /home/krit/nix/users/krit/nixos/programs/file-managers/dolphin.nix
    /home/krit/nix/users/krit/nixos/programs/gui-programs/helium.nix
    /home/krit/nix/users/krit/nixos/programs/gui-programs/zen-browser/spaces.nix
    /home/krit/nix/users/krit/nixos/programs/progressive-web-apps.nix
    /home/krit/nix/users/krit/nixos/services/hardware/logitech/mouses/logitech-main.nix
    /home/krit/nix/users/krit/nixos/services/nas/borg-backup/borg-backup-desktop.nix
    /home/krit/nix/users/krit/nixos/services/nas/borg-backup/borg-backup-laptop.nix
    /home/krit/nix/users/krit/nixos/services/nas/owncloud.nix
    /home/krit/nix/users/krit/nixos/services/nas/smb.nix
    /home/krit/nix/users/krit/nixos/services/nas/ssh.nix
    /home/krit/nix/users/krit/nixos/specializations/entertainment.nix
    /home/krit/nix/users/krit/nixos/specializations/home.nix
    /home/krit/nix/users/krit/nixos/specializations/school.nix
  ];

  config = (denix.lib.configurations {
    moduleSystem = "nixos";
    homeManagerUser = "krit";
    extensions = with denix.lib.extensions; [
      args
      (base.withConfig {
        args.enable = true;
        rices.enable = false;
      })
    ];
    specialArgs = {
      inputs = flake.inputs;
      moduleSystem = "nixos";
    };
    paths = [
      /home/krit/nix/templates/tests/nixos/test-arch-compat/shared/host-tlp-sddm-pixie.nix
      /home/krit/nix/templates/tests/nixos/test-arch-compat/shared/local-packages.nix
    ] ++ nixosPaths;
    exclude = [ ];
  }).arch-compat-b.config;

  hm = config.home-manager.users.krit;
  spec = name: config.specialisation.${name}.configuration.home-manager.users.krit;
in
{
  "all-modules-tlp-sddm-pixie" = hm.home.activationPackage;
  "specialisation-deep-focus-tlp" = (spec "deep-focus").home.activationPackage;
  "specialisation-guest-tlp" = (spec "guest").home.activationPackage;
  "specialisation-safe-mode-tlp" = (spec "safemode").home.activationPackage;
  "specialisation-secure-travel-tlp" = (spec "secure-travel").home.activationPackage;
}
