{ delib, lib, moduleSystem, ... }:
delib.module {
  name = "programs.yazi";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
    extraPackages = delib.listOfOption lib.types.package [ ];
    extraInitLua = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Lua prepended to the generated yazi init.lua.";
    };
  };

  home.ifEnabled = { cfg, myconfig, ... }: {
    home.packages = cfg.extraPackages;

    programs.yazi = {
      enable = true;
      enableZshIntegration = myconfig.constants.shell == "zsh";
      enableFishIntegration = myconfig.constants.shell == "fish";
      enableBashIntegration = myconfig.constants.shell == "bash";
      initLua = lib.mkIf (cfg.extraInitLua != "") (lib.mkBefore cfg.extraInitLua);
    };

    xdg.desktopEntries.yazi = lib.mkIf (moduleSystem == "nixos") (lib.mapAttrs (_: lib.mkDefault) {
      name = "Yazi";
      genericName = "File Manager";
      exec = "yazi";
      icon = "system-file-manager";
      terminal = true;
      categories = [ "System" "FileTools" "FileManager" ];
      mimeType = [ "inode/directory" ];
    });
  };
}
