{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    # 📦 Core Packages (Lightweight stuff everyone needs)
    extraPackages = with pkgs; [
      ripgrep
      fd
      xclip
    ];
  };
}
