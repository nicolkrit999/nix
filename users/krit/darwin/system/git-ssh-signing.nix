{ delib
, lib
, pkgs
, ...
}:
let
  schoolEmail = "kritpio.nicol@student.supsi.ch";
  schoolPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBRKQLjixO72qgAc64gzJwsmOdoNQs+KkQg8GewHnm66";
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
        default = [ "${schoolEmail} ${schoolPubKey}" ];
        description = "Additional complete allowed_signers lines (principal and key) appended after the primary one; defaults to the school principal.";
      };
    };

  # pinentry_mac is not installed on purpose: signing is SSH-format and never reaches
  # gpg-agent, and nixpkgs' gnupg already hardwires pinentry_mac on darwin. If GPG is ever
  # used on the Mac, verify on a real Mac that gpg still finds a pinentry.
  darwin.ifEnabled.environment.systemPackages = [ pkgs.gnupg ];

  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      sshDir = "/Users/${myconfig.constants.user}/.ssh";
    in
    {
      programs.git = {
        enable = true;
        # signByDefault additionally enables tag.gpgSign
        signing.signByDefault = true;
        settings = {
          gpg.format = "ssh";
          user.signingKey = if cfg.signingKey != null then cfg.signingKey else "${sshDir}/id_github";
          commit.gpgSign = true;
          gpg.ssh.allowedSignersFile = "${sshDir}/allowed_signers";
        };
        includes = [
          {
            condition = "gitdir:~/school-workspace/**";
            contents.user = {
              email = schoolEmail;
              name = "Krit Pio Nicol-University";
              signingkey = "${sshDir}/id_school";
            };
          }
        ];
      };

      home.file.".ssh/allowed_signers".text = lib.concatMapStrings (line: line + "\n") (
        [ "${cfg.allowedSignersEmail} ${cfg.allowedSignersPubKey}" ] ++ cfg.extraAllowedSigners
      );
    };
}
