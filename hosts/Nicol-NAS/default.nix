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
    };
}
