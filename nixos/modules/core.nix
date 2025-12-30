{
  # ---------------------------------------------------------
  # ⚙️ SYSTEM CORE
  # ---------------------------------------------------------
  # Import all your hardware/system configs here.
  # ❌ DO NOT import desktop environments or window managers here
  # (they are managed based on flake.nix)
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./boot.nix
    ./cosmic.nix
    ./env.nix
    ./guest.nix
    ./home-manager.nix
    ./kernel.nix
    ./net.nix
    ./nh.nix
    ./nix.nix
    ./sddm.nix
    ./tailscale.nix
    ./timezone.nix
    ./user.nix
    ./zram.nix
  ];
}
