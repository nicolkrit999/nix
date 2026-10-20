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
    _:
    {
      constants = {
        hostname = "Nicol-NAS";
        user = "krit";

        gitUserName = "Krit Pio Nicol";
        gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

        editor = "nvim";
        fileManager = "yazi";

        theme = {
          base16Theme = "gruvbox-material-dark-hard";
          catppuccinFlavor = "macchiato";
          catppuccinAccent = "sapphire";
        };

        homeStateVersion = "26.05";
      };

      # ---------------------------------------------------------------
      # 🌐 TOP-LEVEL MODULES
      # ---------------------------------------------------------------
      nix-sweeps.enable = true;
      nh.enable = true; # home-manager nh + nh-clean user timer: the scheduled GC of this home-only build (nix-sweeps only adds the CLI and presets)

      stylix = {
        enable = true;
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
        headroom.enable = true;
        agent-reach = {
          enable = true;
          browserChannels = false;
        };

        git = {
          enable = true;
        };

        claude-code = {
          enable = true;
          mcpSecrets = [
            { sopsSecret = "claude_mcp_context7_api_key"; }
            { sopsSecret = "claude_mcp_github_token"; }
          ];
        };
      };

      # ---------------------------------------------------------------
      # 👤 KRIT
      # ---------------------------------------------------------------
      krit = {
        commonSopsSecrets.enable = true;
        programs.yazi.enable = true;
        services.nicol-nas.local-packages.enable = true;
        system = {
          git-ssh-signing.enable = true;
          ssh-config.enable = true;
        };
      };

      # ---------------------------------------------------------------
      # 🧰 SERVICES
      # ---------------------------------------------------------------
      services = {
        external.dotfiles-private.enable = true;
        hypridle.enable = false; # idle daemon, Wayland-only
        swaync.enable = false; # notification center, Wayland-only
        audio.enable = false; # NixOS-only module (no home block), disabled anyway; the NAS has no sound hardware
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

      qt.enable = false; # Qt/KDE theming packages (qt5ct, qt6ct, papirus-icon-theme, breeze, ...)
      mime.enable = false; # xdg.mimeApps/.desktop-entry noise - nothing ever reads these headless
      home-packages.enable = false; # NixOS-only terminal/browser/editor package translation - not applicable, no home.* block today, disabled anyway
      zram.enable = false; # NixOS-only swap config - not applicable, no home.* block today, disabled anyway
      cachix.enable = false; # NixOS/Darwin-only substituter config - not applicable to this home-only build, disabled anyway

    };
}
