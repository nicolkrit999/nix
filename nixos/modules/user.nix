{ pkgs, vars, ... }:
let
  # 🛡️ FALLBACK: Defaults to "zsh" if vars.shell is missing
  currentShell = vars.shell or "zsh";

  shellPkg =
    if currentShell == "fish" then
      pkgs.fish
    else if currentShell == "zsh" then
      pkgs.zsh
    else
      pkgs.bashInteractive;
in
{
  programs.zsh.enable = currentShell == "zsh";
  programs.fish.enable = currentShell == "fish";

  users = {
    defaultUserShell = shellPkg;
    users.${vars.user} = {
      isNormalUser = true;
      shell = shellPkg;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
    };
  };
}
