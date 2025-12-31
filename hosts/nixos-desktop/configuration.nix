{
  config,
  pkgs,
  lib,
  vars,
  ...
}:

{
  # home.nix and host-modules are imported from flake.nix
  imports = [
    # Hardware scan (auto-generated)
    ./hardware-configuration.nix

    # Packages specific to this machine
    ./local-packages.nix

    # Secrets Management (not added to GitHub)
    (import /etc/nixos/secrets/secrets.nix)

    # Flatpak support
    ./flatpak.nix

    # Core imports
    ../../nixos/modules/core.nix

    # These are manually imported here because they contains aspects that home-manager can not handle alone
    ./host-modules/logitech.nix # boot
    ./host-modules/smb.nix # user
    ./host-modules/gaming.nix # hardware
    ./host-modules/borg-backup.nix # networking
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
    foot # Backup terminal in case other fails. This does not require particular configuration
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
  networking.hostName = vars.hostname;
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
    layout = vars.keyboardLayout;
    variant = vars.keyboardVariant;
  };
  console.useXkbConfig = true;

  # ---------------------------------------------------------
  # 👤 USER CONFIGURATION
  # ---------------------------------------------------------
  users.users.${vars.user} = {
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

  system.stateVersion = vars.stateVersion;

  i18n.inputMethod.enabled = lib.mkForce null;
  environment.variables.GTK_IM_MODULE = lib.mkForce "";
  environment.variables.QT_IM_MODULE = lib.mkForce "";
  environment.variables.XMODIFIERS = lib.mkForce "";
}
