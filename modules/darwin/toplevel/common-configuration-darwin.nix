{ delib
, pkgs
, ...
}:
delib.module {
  name = "common-configuration";

  darwin.always =
    { myconfig, ... }:
    let
      shell = myconfig.constants.shell or "fish";
      hostname = myconfig.constants.hostname or "mac";
      user = myconfig.constants.user or "krit";
      shellPkg =
        if shell == "fish" then
          pkgs.fish
        else if shell == "zsh" then
          pkgs.zsh
        else
          pkgs.bashInteractive;
    in
    {
      system.defaults = {
        dock.autohide = true;
        finder.AppleShowAllExtensions = true;
        NSGlobalDomain.AppleInterfaceStyle = "Dark";
      };

      security.pam.services.sudo_local.touchIdAuth = true;
      security.pam.services.sudo_local.reattach = true;

      networking.hostName = hostname;
      networking.computerName = hostname;
      system.stateVersion = myconfig.constants.darwinStateVersion or 4;

      home-manager.backupFileExtension = "hm-backup";

      ids.gids.nixbld = 350;

      environment.systemPackages = with pkgs; [
        nixfmt
        sops
        shellPkg
        age
        nix-prefetch-scripts
      ];

      environment.systemPath = [
        "/nix/var/nix/profiles/per-user/${user}/profile/bin"
        "/opt/homebrew/bin"
      ];

      programs.zsh.enable = true;
      programs.zsh.interactiveShellInit =
        if shell == "fish" then
          ''
            if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'fish' ]]; then
              exec ${pkgs.fish}/bin/fish -l
            fi
          ''
        else
          "";

      programs.fish = {
        enable = true;
      };
    };
}
