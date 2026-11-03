{ delib, ... }:
delib.module {
  name = "krit.system.ssh-config";
  options = delib.singleEnableOption false;

  darwin.ifEnabled = _: {
    programs.ssh.knownHosts = {
      "[gitea-ssh.nicolkrit.ch]:2222" = {
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCA8VQtkhSH0wg2Xvi5FjIofM4XMo/+PrFVFdVnu/wC";
      };
    };
  };

  home.ifEnabled =
    { myconfig, ... }:
    let
      nas = myconfig.krit.services.nas;
      sshDir = "/Users/${myconfig.constants.user}/.ssh";
    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "github.com" = {
            IdentityFile = "${sshDir}/id_github";
          };
          "nicol-nas" = {
            HostName = nas.host;
            IdentityFile = "${sshDir}/id_github";
            IdentitiesOnly = true;
            User = nas.user;
          };
          "gitea-ssh.nicolkrit.ch" = {
            IdentityFile = "${sshDir}/id_github";
            IdentitiesOnly = true;
            Port = 2222;
          };
          "gitlab-edu.supsi.ch" = {
            IdentityFile = "${sshDir}/id_school";
            IdentitiesOnly = true;
          };
          "github-school" = {
            HostName = "github.com";
            IdentityFile = "${sshDir}/id_school";
            IdentitiesOnly = true;
          };
        };
      };
    };
}
