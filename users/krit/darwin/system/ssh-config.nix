{ delib, lib, ... }:
delib.module {
  name = "krit.system.ssh-config";
  options = with delib; moduleOptions {
    enable = boolOption false;
    # Adds the `gateway` alias (UniFi Cloud Gateway Fiber console shell, root@192.168.1.1)
    gatewayAlias = boolOption false;
  };

  darwin.ifEnabled = _: {
    programs.ssh.knownHosts = {
      "[gitea-ssh.nicolkrit.ch]:2222" = {
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCA8VQtkhSH0wg2Xvi5FjIofM4XMo/+PrFVFdVnu/wC";
      };
    };
  };

  home.ifEnabled =
    { cfg, myconfig, ... }:
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
        } // lib.optionalAttrs cfg.gatewayAlias {
          # Dedicated sops-managed id_gateway (not id_github); its pubkey must be in root's authorized_keys on the gateway.
          "gateway" = {
            HostName = "192.168.1.1";
            User = "root";
            IdentityFile = "${sshDir}/id_gateway";
            IdentitiesOnly = true;
          };
        };
      };
    };
}
