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

        shell = "bash";
        editor = "nvim";
        fileManager = "yazi";

        theme = {
          polarity = "dark";
          base16Theme = "gruvbox-material-dark-hard";
          catppuccin = false;
          catppuccinFlavor = "macchiato";
          catppuccinAccent = "sapphire";
        };

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

        git = {
          enable = true;
          customGitIgnores = [ ];
        };

        claude-code = {
          enable = true;
          mcpSecrets = [
            { sopsSecret = "openrouter_api_claude_code"; envVar = "OPENROUTER_API_KEY"; }
            { sopsSecret = "claude_mcp_actual_password"; envVar = "ACTUAL_PASSWORD"; }
            { sopsSecret = "claude_mcp_actual_sync_id"; envVar = "ACTUAL_SYNC_ID"; }
            { sopsSecret = "claude_mcp_actual_encryption_password"; envVar = "ACTUAL_BUDGET_ENCRYPTION_PASSWORD"; }
            { sopsSecret = "claude_mcp_context7_api_key"; envVar = "CONTEXT7_API_KEY"; }
            { sopsSecret = "claude_mcp_openai_api_key"; envVar = "OPENAI_API_KEY"; }
            { sopsSecret = "claude_mcp_milvus_token"; envVar = "MILVUS_TOKEN"; }
            { sopsSecret = "claude_mcp_github_token"; envVar = "GITHUB_TOKEN"; }
            { sopsSecret = "claude_mcp_portainer_token"; envVar = "PORTAINER_TOKEN"; }
            { sopsSecret = "claude_mcp_sparkyfitness_api_key"; envVar = "SPARKYFITNESS_API_KEY"; }
            #{ sopsSecret = "claude_mcp_kagi_api_key"; envVar = "KAGI_API_KEY"; }
          ];
          mcpEnv = {
            ACTUAL_SERVER_URL = "https://budget.nicolkrit.ch";
          };
        };
      };

      # ---------------------------------------------------------------
      # 👤 KRIT PROGRAMS
      # ---------------------------------------------------------------
      krit.programs.yazi.enable = true;

      # ---------------------------------------------------------------
      # 🧰 SERVICES
      # ---------------------------------------------------------------
      services.external.dotfiles-private.enable = true;

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
