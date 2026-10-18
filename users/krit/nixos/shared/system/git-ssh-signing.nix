{ delib, lib, pkgs, moduleSystem, ... }:
let
  # Shared home-manager half: ssh-format commit signing + allowed_signers.
  # Used by both the NixOS path (nested under home-manager.users.<user>) and
  # the standalone home-manager path below - kept in one place so they can't
  # drift apart.
  mkGitSigningHM =
    { cfg, homeDir }:
    {
      programs.git = {
        enable = true;
        settings = {
          gpg.format = "ssh";
          user.signingKey =
            if cfg.signingKey != null then cfg.signingKey else "${homeDir}/.ssh/id_github";
          commit.gpgSign = true;
          gpg.ssh.allowedSignersFile = "${homeDir}/.ssh/allowed_signers";
        };
      };

      home.file.".ssh/allowed_signers".text = lib.concatMapStrings (line: line + "\n") (
        [ "${cfg.allowedSignersEmail} ${cfg.allowedSignersPubKey}" ] ++ cfg.extraAllowedSigners
      );
    };
in
delib.module {
  name = "krit.system.git-ssh-signing";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      signingKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "SSH signing key path; null means ~/.ssh/id_github of the user.";
      };
      allowedSignersEmail = strOption "githubgitlabmain.hu5b7@passfwd.com";
      allowedSignersPubKey = strOption "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO4fJZtoawnvuR2D/CAk7fBrioEyhyagheH4RtTaf8gD";
      extraAllowedSigners = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional complete allowed_signers lines (principal and key) appended after the primary one.";
      };
    };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    {
      # gpg-agent is for GPG only; gcr-ssh-agent is the single SSH agent
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = false;
        pinentryPackage = pkgs.pinentry-qt;
      };

      environment.systemPackages = with pkgs; [
        pinentry-qt
        pinentry-curses
      ];

      home-manager.users.${myconfig.constants.user} =
        _:
        mkGitSigningHM {
          inherit cfg;
          homeDir = "/home/${myconfig.constants.user}";
        };
    };

  # Standalone home-manager builds (e.g. Nicol-NAS) have no NixOS system layer
  # to host the gnupg agent / pinentry-qt - and don't need them anyway,
  # ssh-format signing doesn't go through gpg-agent, and pinentry-qt is a GUI
  # prompt with nothing to display on a headless NAS. Only the home-manager
  # half applies here.
  #
  # Guarded via a plain `if moduleSystem == "home"`, NOT `lib.mkIf`: denix
  # nests this same `home.ifEnabled` body inside `home-manager.users.<user>`
  # for NixOS/Darwin builds too, where `programs.git`/`home.file` are already
  # set by the nixos.ifEnabled path above - `lib.mkIf` would keep this
  # branch's attribute paths structurally present even when false, causing
  # duplicate-definition or option-existence issues; a plain `if` makes the
  # untaken branch evaluate to `{ }` (structurally absent) instead. See
  # feedback_delib_home_ifenable_patterns memory.
  home.ifEnabled =
    { cfg, myconfig, ... }:
    if moduleSystem == "home" then
      mkGitSigningHM
        {
          inherit cfg;
          homeDir = "/home/${myconfig.constants.user}";
        }
    else
      { };
}
