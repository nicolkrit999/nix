{ delib
, pkgs
, lib
, inputs
, ...
}:
delib.module {
  name = "programs.npm";
  options = delib.moduleOptions {
    enable = delib.boolOption false;
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    hostPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
  };

  home.ifEnabled = { myconfig, ... }: {
    home.packages = [ pkgs.nodejs_latest ] ++ myconfig.programs.npm.hostPackages;

    home.file.".npmrc".text = ''
      prefix = ''${HOME}/.npm-global
    '';

    home.sessionPath = [ "$HOME/.npm-global/bin" ];

    home.activation = lib.optionalAttrs (myconfig.programs.npm.packages != [ ]) {
      npmGlobalPackages = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD env PATH="${pkgs.nodejs_latest}/bin:$PATH" ${pkgs.nodejs_latest}/bin/npm install -g ${lib.concatStringsSep " " myconfig.programs.npm.packages}
      '';
    };
  };
}
