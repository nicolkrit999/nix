# Arch-compat scenario A: all modules + auto-cpufreq + sddm-astronaut.
# Returns an attrset of home.activationPackage derivations (one per batch),
# suitable for `nix build --dry-run --file this.nix --attr <name>`.
# Evaluating the full activationPackage closure forces every transitive
# derivation to be resolved for aarch64-linux - any missing package throws.
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;

  nixosPaths = [
    # aarch64 platform + home-manager base + stylix
    (src + "/templates/tests/nixos/test-arch-compat/shared/nixos-extra-aarch64")

    # Core setup
    (src + "/modules/common/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants-nixos.nix")
    (src + "/modules/nixos/toplevel/nix-nixos.nix")
    (src + "/modules/common/themes/catppuccin.nix")

    # Always-on infra that carries the gpu-screen-recorder overlay
    (src + "/modules/nixos/toplevel/common-configuration-nixos.nix")

    # WM toplevel enable options
    (src + "/modules/nixos/toplevel/hyprland.nix")
    (src + "/modules/nixos/toplevel/niri.nix")
    (src + "/modules/nixos/toplevel/mango.nix")
    (src + "/modules/nixos/toplevel/gnome.nix")
    (src + "/modules/nixos/toplevel/kde.nix")
    (src + "/modules/nixos/toplevel/cosmic.nix")

    # Window manager modules
    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-main.nix")
    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-binds.nix")
    (src + "/modules/nixos/programs/de-wm/niri/niri-main.nix")
    (src + "/modules/nixos/programs/de-wm/niri/niri-binds.nix")
    (src + "/modules/nixos/programs/de-wm/mango/mango-main.nix")
    (src + "/modules/nixos/programs/de-wm/mango/mango-binds.nix")
    (src + "/modules/nixos/programs/de-wm/gnome/gnome-main.nix")
    (src + "/modules/nixos/programs/de-wm/gnome/gnome-binds.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-main.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-binds.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-desktop.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-files.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-inputs.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-krunner.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-kscreenlocker.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-panels.nix")
    (src + "/modules/nixos/programs/de-wm/cosmic/cosmic-main.nix")

    # Custom shells
    (src + "/modules/nixos/programs/shells/caelestia-main.nix")
    (src + "/modules/nixos/programs/shells/noctalia-main.nix")

    # Waybars
    (src + "/modules/nixos/programs/waybar/hyprland/waybar-hyprland.nix")
    (src + "/modules/nixos/programs/waybar/niri/waybar-niri.nix")
    (src + "/modules/nixos/programs/waybar/mango/waybar-mango.nix")

    # Common programs
    (src + "/modules/common/programs/shells/bash.nix")
    (src + "/modules/common/programs/shells/fish.nix")
    (src + "/modules/common/programs/shells/zsh.nix")
    (src + "/modules/common/programs/shells/shell-aliases.nix")
    (src + "/modules/common/programs/shells/starship.nix")
    (src + "/modules/common/programs/shells/fzf.nix")
    (src + "/modules/common/programs/shells/lazygit.nix")
    (src + "/modules/common/programs/shells/tmux.nix")
    (src + "/modules/common/programs/shells/bat.nix")
    (src + "/modules/common/programs/shells/eza.nix")
    (src + "/modules/common/programs/shells/git.nix")
    (src + "/modules/common/programs/shells/npm.nix")
    (src + "/modules/common/programs/shells/yazi-plugins.nix")
    (src + "/modules/common/programs/shells/zoxide.nix")
    (src + "/modules/common/programs/shells/nix-search-tv/nst-home.nix")
    (src + "/modules/common/programs/claude-code.nix")
    (src + "/modules/common/programs/headroom.nix")
    (src + "/modules/common/programs/comma.nix")
    (src + "/modules/common/programs/doom/doom-main.nix")
    (src + "/modules/common/programs/doom/doom-tree-sitter.nix")
    (src + "/modules/common/programs/nltch-nur.nix")
    (src + "/modules/common/programs/statix.nix")
    (src + "/modules/common/programs/television.nix")
    (src + "/modules/common/programs/zen-browser.nix")
    (src + "/modules/common/services/tailscale.nix")
    (src + "/modules/common/toplevel/cachix.nix")
    (src + "/modules/common/toplevel/nh.nix")
    (src + "/modules/common/toplevel/nix-sweeps.nix")

    # NixOS programs
    (src + "/modules/nixos/programs/cava.nix")
    (src + "/modules/nixos/programs/claude-desktop.nix")
    (src + "/modules/nixos/programs/concord.nix")
    (src + "/modules/nixos/programs/google-antigravity.nix")
    (src + "/modules/nixos/programs/nix-alien.nix")
    (src + "/modules/nixos/programs/nix-ld.nix")
    (src + "/modules/nixos/programs/nix-topology.nix")
    (src + "/modules/nixos/programs/swayosd.nix")
    (src + "/modules/nixos/programs/tgt.nix")
    (src + "/modules/nixos/programs/vicinae.nix")
    (src + "/modules/nixos/programs/walker.nix")

    # Services
    (src + "/modules/nixos/services/audio.nix")
    (src + "/modules/nixos/services/autotrash.nix")
    (src + "/modules/nixos/services/hypr/hypridle.nix")
    (src + "/modules/nixos/services/hypr/hyprlock.nix")
    (src + "/modules/nixos/services/impermanence.nix")
    (src + "/modules/nixos/services/power/auto-cpufreq.nix")
    (src + "/modules/nixos/services/power/thermald.nix")
    (src + "/modules/nixos/services/power/tlp.nix")
    (src + "/modules/nixos/services/resolved.nix")
    (src + "/modules/nixos/services/sddm/sddm-astronaut.nix")
    (src + "/modules/nixos/services/sddm/sddm-pixie.nix")
    (src + "/modules/nixos/services/snapshots.nix")
    (src + "/modules/nixos/services/swaync.nix")

    # System modules
    (src + "/modules/nixos/toplevel/bluetooth.nix")
    (src + "/modules/nixos/toplevel/zram.nix")
    (src + "/modules/nixos/toplevel/net.nix")
    (src + "/modules/nixos/toplevel/qt.nix")
    (src + "/modules/nixos/toplevel/xdg-portal.nix")

    # Specializations
    (src + "/modules/nixos/specializations/deep-focus.nix")
    (src + "/modules/nixos/specializations/guest.nix")
    (src + "/modules/nixos/specializations/safe-mode.nix")
    (src + "/modules/nixos/specializations/secure-travel.nix")

    # users/krit/common - cross-platform user modules
    (src + "/users/krit/common/programs/claude-code-wrappers.nix")
    (src + "/users/krit/common/programs/cli-programs/direnv.nix")
    (src + "/users/krit/common/programs/cli-programs/neovim.nix")
    (src + "/users/krit/common/programs/file-managers/ranger.nix")
    (src + "/users/krit/common/programs/file-managers/yazi/init-lua.nix")
    (src + "/users/krit/common/programs/file-managers/yazi/yazi-keymap.nix")
    (src + "/users/krit/common/programs/file-managers/yazi/yazi.nix")
    (src + "/users/krit/common/programs/file-managers/yazi/yazi-theme.nix")
    (src + "/users/krit/common/programs/gui-programs/chromium.nix")
    (src + "/users/krit/common/programs/gui-programs/firefox.nix")
    (src + "/users/krit/common/programs/gui-programs/librewolf/librewolf-common.nix")
    # profiles/librewolf-profile-{default,privacy}.nix excluded: they are { addons, ... } helper
    # functions called by librewolf-common.nix, not standalone denix modules.
    (src + "/users/krit/common/programs/gui-programs/zathura.nix")
    (src + "/users/krit/common/programs/gui-programs/zen-browser/extensions.nix")
    (src + "/users/krit/common/programs/gui-programs/zen-browser/keyboard.nix")
    (src + "/users/krit/common/programs/gui-programs/zen-browser/mods.nix")
    (src + "/users/krit/common/programs/gui-programs/zen-browser/pins.nix")
    (src + "/users/krit/common/programs/gui-programs/zen-browser/search.nix")
    (src + "/users/krit/common/programs/gui-programs/zen-browser/settings.nix")
    (src + "/users/krit/common/programs/terminal-emulators/alacritty.nix")
    (src + "/users/krit/common/programs/terminal-emulators/kitty.nix")
    (src + "/users/krit/common/toplevel/attic.nix")

    # users/krit/nixos - NixOS-specific user modules (ext-dotfiles excluded: pure symlinks, no arch risk)
    (src + "/users/krit/nixos/common/home/home-base.nix")
    (src + "/users/krit/nixos/common/system/default-user.nix")
    (src + "/users/krit/nixos/common/system/git-ssh-signing.nix")
    (src + "/users/krit/nixos/common/system/ssh-config.nix")
    (src + "/users/krit/nixos/common/system/swiss-locale.nix")
    (src + "/users/krit/nixos/common/system/virtualisation.nix")
    (src + "/users/krit/nixos/programs/file-managers/dolphin.nix")
    (src + "/users/krit/nixos/programs/gui-programs/helium.nix")
    (src + "/users/krit/nixos/programs/gui-programs/zen-browser/spaces.nix")
    (src + "/users/krit/nixos/programs/progressive-web-apps.nix")
    (src + "/users/krit/nixos/services/hardware/logitech/mouses/logitech-main.nix")
    (src + "/users/krit/nixos/services/nas/borg-backup/borg-backup-desktop.nix")
    (src + "/users/krit/nixos/services/nas/borg-backup/borg-backup-laptop.nix")
    (src + "/users/krit/nixos/services/nas/owncloud.nix")
    (src + "/users/krit/nixos/services/nas/smb.nix")
    (src + "/users/krit/nixos/services/nas/ssh.nix")
    (src + "/users/krit/nixos/specializations/entertainment.nix")
    (src + "/users/krit/nixos/specializations/home.nix")
    (src + "/users/krit/nixos/specializations/school.nix")
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
      (src + "/templates/tests/nixos/test-arch-compat/shared/host-auto-cpufreq-sddm-astronaut.nix")
      (src + "/templates/tests/nixos/test-arch-compat/shared/local-packages.nix")
    ] ++ nixosPaths;
    exclude = [ ];
  }).arch-compat-a.config;

  hm = config.home-manager.users.krit;
  spec = name: config.specialisation.${name}.configuration.home-manager.users.krit;
in
{
  "all-modules-auto-cpufreq-sddm-astronaut" = hm.home.activationPackage;
  "specialisation-deep-focus-auto-cpufreq" = (spec "deep-focus").home.activationPackage;
  "specialisation-guest-auto-cpufreq" = (spec "guest").home.activationPackage;
  "specialisation-safe-mode-auto-cpufreq" = (spec "safemode").home.activationPackage;
  "specialisation-secure-travel-auto-cpufreq" = (spec "secure-travel").home.activationPackage;
}
