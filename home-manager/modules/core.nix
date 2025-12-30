{
  imports = [
    # ---------------------------------------------------------
    # 👤 USER CORE
    # ---------------------------------------------------------
    # ❌ DO NOT import desktop environments or window managers here
    # (they are managed based on flake.nix)

    ./alacritty.nix
    ./bat.nix
    ./cava.nix
    ./chromium.nix
    ./dolphin.nix
    ./firefox.nix
    ./eza.nix
    ./git.nix
    ./kitty.nix
    ./lazygit.nix
    ./mime.nix
    ./neovim.nix
    ./qt.nix
    ./ranger.nix
    ./starship.nix
    ./stylix.nix
    ./tmux.nix
    ./zathura.nix
    ./zsh.nix
    ./wofi
  ];
}
