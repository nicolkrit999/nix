{ pkgs, vars, ... }:
{
  programs.zsh.enable = true; # Enable Zsh as a shell

  users = {
    defaultUserShell = pkgs.zsh; # Sets Zsh as the default shell for the user
    users.${vars.user} = {
      isNormalUser = true; # Marks this account as a regular user

      # Group permissions:
      # wheel: Allows use of 'sudo' for administrative tasks
      # networkmanager: Allows the user to change Wi-Fi/Ethernet settings
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
    };
  };
}
