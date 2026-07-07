# Nicol-NAS - UGREEN NAS running UGOS (Debian 12 bookworm, foreign distro).
#
# Home-manager-only host: NO NixOS system config exists or is possible here.
# `/` is UGOS's own overlayfs; `/nix` is a bind mount from /volume2/nix (the
# NVMe data volume, chosen deliberately to avoid UGOS's system-disk wipe risk
# on firmware updates). Activated via:
#   home-manager switch --flake ~/nix#krit@Nicol-NAS
#
# This flake host name matches the machine's actual hostname ("Nicol-NAS"),
# so home-manager's automatic $USER@$(hostname) target resolution works too -
# but pin the flake attr explicitly as shown above for clarity/reliability.
{ delib, ... }:
delib.host {
  name = "Nicol-NAS";
  type = "server";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    { ... }:
    {
      constants = {
        hostname = "Nicol-NAS";
        user = "krit";
        mainLocale = "en_US.UTF-8";

        gitUserName = "Krit Pio Nicol";
        gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

        shell = "bash"; # Fixed login shell on this foreign-distro appliance
        editor = "nvim";
        fileManager = "yazi";

        # Same theme as hosts/nixos-desktop/default.nix. On this headless,
        # standalone home-manager build stylix only themes CLI targets
        # (starship, tmux, bat, lazygit, ...) via base16Scheme - there's no
        # wallpaper/image and none is added (see stylix = {...} below and
        # modules/nixos/toplevel/stylix-nixos.nix, whose home.ifEnabled now
        # sets base16Scheme unconditionally rather than gating it on a
        # wallpapers constant).
        theme = {
          polarity = "dark";
          base16Theme = "gruvbox-material-dark-hard";
          catppuccin = false;
          catppuccinFlavor = "macchiato";
          catppuccinAccent = "sapphire";
        };

        # New host, installed under 26.05 - frozen forever from this point on.
        # ⛔ Never bump this, and never let a repo-wide stateVersion sweep touch it.
        homeStateVersion = "26.05";
      };

      # ---------------------------------------------------------------
      # 🌐 TOP-LEVEL MODULES
      # ---------------------------------------------------------------
      krit.commonSopsSecrets.enable = true;

      nix-sweeps = {
        enable = true;
        gcd = "30d";
        gcn = "3";
      };

      # Same style/position as hosts/nixos-desktop/default.nix. Headless here
      # means no wallpaper/image target, but stylix still themes CLI tools
      # (starship, tmux, bat, lazygit, ...) via base16Scheme alone - see the
      # theme = {...} constants above and modules/nixos/toplevel/stylix-nixos.nix.
      stylix = {
        enable = true;
        # kde/gtk targets default-enable (stylix-nixos.nix's home.ifEnabled
        # sets them `!isCatppuccin`) and pull in stylix-kde-theme/adw-gtk3 -
        # neither GTK nor KDE exist on this headless NAS, so switch them
        # off explicitly. qt stays untouched here (already off via the
        # separate qt.enable = false module below - not a stylix target).
        # Fonts are left alone: harmless on a headless host.
        targets = {
          kde.enable = false;
          gtk.enable = false;
        };
      };

      # ---------------------------------------------------------------
      # 🚀 PROGRAMS
      # ---------------------------------------------------------------
      programs = {
        bat.enable = true;
        eza.enable = true;
        fzf.enable = true;
        lazygit.enable = true;
        shell-aliases.enable = true;
        starship.enable = true;
        tmux.enable = true;
        zoxide.enable = true;

        git = {
          enable = true;
          customGitIgnores = [ ];
        };

        # See project memory / final report: mcpSecrets/mcpEnv are declared
        # options on programs.claude-code but are not consumed anywhere in its
        # own home.ifEnabled block - the real consumers (claude-code-wrappers.nix)
        # hardcode NixOS-style /run/secrets/<name> paths, which don't exist on a
        # home-manager-standalone host. Left empty deliberately - not a hack
        # around a missing feature, just not wiring secrets that have nowhere
        # home-manager-side to resolve to yet.
        claude-code = {
          enable = true;
          mcpSecrets = [ ];
          mcpEnv = { };
        };
      };

      # ---------------------------------------------------------------
      # 👤 KRIT PROGRAMS
      # ---------------------------------------------------------------
      krit.programs.yazi.enable = true;

      # ---------------------------------------------------------------
      # 👤 KRIT SERVICES
      # ---------------------------------------------------------------
      krit.services.nicol-nas.local-packages.enable = true;

      # ---------------------------------------------------------------
      # 🔧 KRIT SYSTEM
      # ---------------------------------------------------------------
      krit.system = {
        git-ssh-signing.enable = true;
        ssh-config.enable = true;
      };

      # ---------------------------------------------------------------
      # ⛔ EXPLICITLY DISABLED - default-true modules not wanted on the NAS

      # 🚀 Programs
      programs.hyprland.enable = false; # master WM switch - see below
      programs.vicinae.enable = false; # GUI launcher + systemd service
      programs.swayosd.enable = false; # on-screen-display overlay, Wayland-only
      programs.waybar-hyprland.enable = false; # status bar, gated on hyprland but disabled explicitly anyway
      programs.waybar-niri.enable = false; # status bar, gated on niri (already off) but disabled explicitly anyway
      programs.waybar-mango.enable = false; # status bar, gated on mango (already off) but disabled explicitly anyway

      # 🧰 Services
      services.hyprlock.enable = false; # lock screen, Wayland-only
      services.hypridle.enable = false; # idle daemon, Wayland-only
      services.swaync.enable = false; # notification center, Wayland-only
      services.audio.enable = false; # pipewire/pulse/alsa - this NAS has no sound hardware
      qt.enable = false; # Qt/KDE theming packages (qt5ct, qt6ct, papirus-icon-theme, breeze, ...)
      mime.enable = false; # xdg.mimeApps/.desktop-entry noise - nothing ever reads these headless
      home-packages.enable = false; # NixOS-only terminal/browser/editor package translation - not applicable, no home.* block today, disabled anyway
      zram.enable = false; # NixOS-only swap config - not applicable, no home.* block today, disabled anyway
      cachix.enable = false; # NixOS/Darwin-only substituter config - not applicable to this home-only build, disabled anyway
      nh.enable = false; # NixOS/Darwin-only `nh` CLI + GC wrapper - not applicable to this home-only build, disabled anyway (this NAS's GC is already handled by nix-sweeps above)

    };
}
