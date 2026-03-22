{ delib, ... }:
delib.module {
  name = "krit.system.ssh-config";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = { myconfig, ... }: {
    programs.ssh.extraConfig = ''
      Host nicol-nas 192.168.1.98 ssh.nicolkrit.ch
        IdentityFile /home/${myconfig.constants.user}/.ssh/id_github
        IdentitiesOnly yes
        User krit

      Host github.com
        IdentityFile /home/${myconfig.constants.user}/.ssh/id_github
    '';
  };
}
