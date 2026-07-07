{ delib, pkgs, moduleSystem, ... }:
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
          user.signingKey = cfg.signingKey;
          commit.gpgSign = true;
          gpg.ssh.allowedSignersFile = "${homeDir}/.ssh/allowed_signers";
        };
      };

      home.file.".ssh/allowed_signers".text = ''
        ${cfg.allowedSignersEmail} ${cfg.allowedSignersPubKey}
      '';
    };
in
delib.module {
  name = "krit.system.git-ssh-signing";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      signingKey = strOption "/home/krit/.ssh/id_github";
      allowedSignersEmail = strOption "githubgitlabmain.hu5b7@passfwd.com";
      allowedSignersPubKey = strOption "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO4fJZtoawnvuR2D/CAk7fBrioEyhyagheH4RtTaf8gD";
    };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    {
      # GPG agent for SSH signing
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        pinentryPackage = pkgs.pinentry-qt;
      };

      environment.systemPackages = with pkgs; [
        gnupg
        pinentry-qt
        pinentry-curses
      ];

      home-manager.users.${myconfig.constants.user} =
        { ... }:
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
