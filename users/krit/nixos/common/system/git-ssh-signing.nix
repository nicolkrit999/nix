{ delib, pkgs, ... }:
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
        {
          programs.git = {
            enable = true;
            settings = {
              gpg.format = "ssh";
              user.signingKey = cfg.signingKey;
              commit.gpgSign = true;
              gpg.ssh.allowedSignersFile = "/home/${myconfig.constants.user}/.ssh/allowed_signers";
            };
          };

          home.file.".ssh/allowed_signers".text = ''
            ${cfg.allowedSignersEmail} ${cfg.allowedSignersPubKey}
          '';
        };
    };
}
