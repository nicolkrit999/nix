{ pkgs, lib, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    package = lib.hiPrio pkgs.neovim-unwrapped;

    extraPackages = with pkgs; [
      ripgrep
      fd
      xclip
      gcc
      gnumake
      fzf
    ];
  };
}
