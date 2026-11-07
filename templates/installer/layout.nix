{
  espLabel = "NIXOS-BOOT";
  btrfsLabel = "nixos";
  luksPartLabel = "nixos-luks";
  luksMapperName = "cryptroot";
  rootTmpfsSize = "4G";
  subvolumes = {
    persist = "@persist";
    home = "@home";
    nix = "@nix";
    log = "@log";
  };
}
