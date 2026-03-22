{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "krit.system.git-ssh-signing";
  options = delib.singleEnableOption false;

  darwin.ifEnabled =
    { ... }:
    {
      environment.systemPackages = with pkgs; [
        gnupg
        pinentry_mac
      ];
    };

  home.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user;
      sshDir = "/Users/${user}/.ssh";
    in
    {
      programs.gpg.enable = lib.mkForce false;
      services.gpg-agent.enable = lib.mkForce false;

      programs.git = {
        signing = lib.mkForce {
          key = "${sshDir}/id_github";
          signByDefault = true;
        };
        settings = {
          gpg.format = lib.mkForce "ssh";
          user.signingKey = lib.mkForce "${sshDir}/id_github";
          commit.gpgSign = lib.mkForce true;
          gpg.ssh.allowedSignersFile = lib.mkForce "${sshDir}/allowed_signers";
        };
        includes = [
          {
            condition = "gitdir:~/school-workspace/**";
            contents = {
              user.email = "kritpio.nicol@student.supsi.ch";
              user.name = "Krit Pio Nicol-University";
              user.signingkey = "${sshDir}/id_school";
            };
          }
        ];
      };

      home.file.".ssh/allowed_signers".text = ''
        githubgitlabmain.hu5b7@passfwd.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO4fJZtoawnvuR2D/CAk7fBrioEyhyagheH4RtTaf8gD
        kritpio.nicol@student.supsi.ch ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBRKQLjixO72qgAc64gzJwsmOdoNQs+KkQg8GewHnm66
      '';
    };
}
