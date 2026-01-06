{ pkgs, lib, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    # ✅ THE FIX:
    # 1. Use 'pkgs.neovim-unwrapped' (safe to override).
    # 2. Use 'lib.hiPrio' to give it priority over the one in home-packages.nix.
    #    This tells Nix: "If there is a conflict, use THIS one."
    package = lib.hiPrio pkgs.neovim-unwrapped;

    extraPackages = with pkgs; [
      ripgrep
      fd
      xclip
      gcc
      gnumake
    ];
  };
}
