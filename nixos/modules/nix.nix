{
  # -----------------------------------------------------------------------
  # ⚙️ PROGRAM: NIX SETTINGS
  # -----------------------------------------------------------------------

  nix.settings = {
    # Enable Flakes
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Deduplicate exact files in the Nix store to save space
    auto-optimise-store = true;

    # 🚀 BINARY CACHES
    substituters = [
      "https://hyprland.cachix.org"
      "https://cosmic.cachix.org"
    ];

    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
    ];
  };

  # 🗑️ GARBAGE COLLECTION
  # Runs weekly to remove unused packages (older than 7 days)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
