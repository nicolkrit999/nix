{
  imports = [
    # Folders modules
    ./yazi

    # Single-file modules
    ./alacritty.nix
    # ./borg-backup.nix # Do not include it because it is already included in configuration.nix
    ./cava.nix
    ./chromium.nix
    ./dolphin.nix
    ./firefox.nix
    #./gaming.nix # Do not include it because it is already included in configuration.nix
    ./kitty.nix
    #./logitech.nix # Do not include it because it is already included in configuration.nix
    ./neovim.nix
    ./ranger.nix
    #./smb.nix # Do not include it because it is already included in configuration.nix
    ./zathura.nix
  ];
}
