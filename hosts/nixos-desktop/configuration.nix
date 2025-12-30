{
  config,
  pkgs,
  lib,
  user,
  stateVersion,
  hostname,
  keyboardLayout,
  keyboardVariant,
  ...
}:

{
  imports = [
    # Hardware scan (auto-generated)
    ./hardware-configuration.nix

    # Packages specific to this machine
    ./local-packages.nix

    # Secrets Management (not added to GitHub)
    (import /etc/nixos/secrets/secrets.nix)

    # Borg Backup Configuration
    ./borg-backup.nix

    # Flatpak support
    ./flatpak.nix

    # Gaming configuration
    ./gaming.nix

    # Logitech MX Master 3S configuration
    ./logitech.nix

    # SMB Shares
    ./smb.nix

    # Core imports
    ../../nixos/modules/core.nix
  ];

  # ---------------------------------------------------------
  # ⚙️ GRAPHICS & FONTS
  # ---------------------------------------------------------
  hardware.graphics.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
  ];
  fonts.fontconfig.enable = true;

  # ---------------------------------------------------------
  # 📦 SYSTEM PACKAGES
  # ---------------------------------------------------------
  environment.systemPackages = with pkgs; [
    iptables
    glib
    gsettings-desktop-schemas
    gtk3
    libsForQt5.qt5.qtwayland
    kdePackages.qtwayland
  ];

  programs.dconf.enable = true;
  programs.zsh.enable = true; # Required for user shell

  # ---------------------------------------------------------
  # 🖥️ HOST IDENTITY & NETWORKING
  # ---------------------------------------------------------
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  # ---------------------------------------------------------
  # 🛠️ NIX SETTINGS (CACHE & FLAKES)
  # ---------------------------------------------------------
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-users = [
      "root"
      "@wheel"
    ];

    # ⚠️ CRITICAL: Use binary cache to avoid compiling from source
    substituters = [ "https://cosmic.cachix.org" ];
    trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
  };

  # ---------------------------------------------------------
  # ⚔️ SYSTEM TWEAKS
  # ---------------------------------------------------------
  systemd.tmpfiles.rules = [
    "f /etc/systemd/logind.conf.d/10-logout-override.conf 0644 root root - [Login]\nKillUserProcesses=yes\nIdleAction=none\n"
  ];

  services.xserver.xkb = {
    layout = keyboardLayout;
    variant = keyboardVariant;
  };
  console.useXkbConfig = true;

  # ---------------------------------------------------------
  # 👤 USER CONFIGURATION
  # ---------------------------------------------------------
  users.users.${user} = {
    isNormalUser = true;
    description = "Primary user";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "docker"
      "video"
      "audio"
    ];
    shell = pkgs.zsh;
  };

  # ---------------------------------------------------------
  # 🌐 BROWSER
  # ---------------------------------------------------------
  programs.chromium = {
    enable = true;
    extraOpts = {
      "ShowHomeButton" = true;
      "HomepageLocation" = "https://www.youtube.com";
      "HomepageIsNewTabPage" = false;
      "RestoreOnStartup" = 4;
      "RestoreOnStartupURLs" = [ "https://www.youtube.com" ];
    };
  };

  system.stateVersion = stateVersion;

  i18n.inputMethod.enabled = lib.mkForce null;
  environment.variables.GTK_IM_MODULE = lib.mkForce "";
  environment.variables.QT_IM_MODULE = lib.mkForce "";
  environment.variables.XMODIFIERS = lib.mkForce "";
}
