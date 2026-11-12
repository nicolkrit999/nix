{ delib
, lib
, ...
}:
delib.module {
  name = "krit.programs.neovim-mime";

  nixos.always = { myconfig, ... }: {
    myconfig.mime.editorDesktopIds = lib.mkIf myconfig.krit.programs.neovim.enable {
      neovim = "custom-nvim.desktop";
      nvim = "custom-nvim.desktop";
    };
  };
}
