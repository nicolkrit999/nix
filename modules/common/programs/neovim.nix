{ delib, lib, ... }:
delib.module {
  name = "programs.neovim";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
    extraPackages = delib.listOfOption lib.types.package [ ];
    extraPlugins = delib.listOfOption lib.types.raw [ ];
    extraWrapperArgs = delib.listOfOption lib.types.str [ ];
  };

  home.ifEnabled = { cfg, ... }: {
    programs.neovim = {
      enable = true;
      inherit (cfg) extraPackages extraWrapperArgs;
      plugins = cfg.extraPlugins;
    };
  };
}
