{ delib, ... }:
delib.module {
  name = "krit.system.ssh-config";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user;
      sshDir = "/Users/${user}/.ssh";
    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "github.com" = {
            identityFile = "${sshDir}/id_github";
          };
          "nicol-nas 192.168.1.98 ssh.nicolkrit.ch" = {
            identityFile = "${sshDir}/id_github";
            identitiesOnly = true;
            user = user;
          };
          "gitlab-edu.supsi.ch" = {
            hostname = "gitlab-edu.supsi.ch";
            identityFile = "${sshDir}/id_school";
            identitiesOnly = true;
          };
          "github-school" = {
            hostname = "github.com";
            identityFile = "${sshDir}/id_school";
            identitiesOnly = true;
          };
        };
      };
    };
}
