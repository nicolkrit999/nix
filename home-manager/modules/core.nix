{
  imports = [
    # ---------------------------------------------------------
    # 👤 USER CORE
    # ---------------------------------------------------------
    # ❌ DO NOT import desktop environments or window managers here
    # (they are managed based on flake.nix)

    ./bat.nix
    ./eza.nix
    ./git.nix
    ./lazygit.nix
    ./mime.nix
    ./neovim.nix
    ./qt.nix
    ./starship.nix
    ./stylix.nix
    ./tmux.nix
    ./zsh.nix
    ./wofi
  ];
}
