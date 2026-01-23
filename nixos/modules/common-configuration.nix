{ config, pkgs, lib, vars, ... }:
let
  shellPkg = if vars.shell == "fish" then
    pkgs.fish
  else if vars.shell == "zsh" then
    pkgs.zsh
  else
    pkgs.bashInteractive;
in {

  # ---------------------------------------------------------
  # 🖥️ HOST IDENTITY
  # ---------------------------------------------------------
  networking.hostName = vars.hostname;
  networking.networkmanager.enable = true;
  system.stateVersion = vars.stateVersion;

  # ---------------------------------------------------------
  # 🌍 LOCALE & TIME
  # ---------------------------------------------------------
  time.timeZone = vars.timeZone;

  # Keyboard Layout
  services.xserver.xkb = {
    layout = vars.keyboardLayout;
    variant = vars.keyboardVariant;
  };
  console.useXkbConfig = true;

  # ---------------------------------------------------------
  # 🛠️ NIX SETTINGS
  # ---------------------------------------------------------
  nix.settings = { trusted-users = [ "root" "@wheel" ]; };

  # Allow unfree packages globally (needed for drivers, code, etc.)
  nixpkgs.config.allowUnfree = true;

  # ---------------------------------------------------------
  # 📦 SYSTEM PACKAGES
  # ---------------------------------------------------------
  environment.systemPackages = with pkgs;
    [
      # --- CLI UTILITIES ---
      dix # Nix diff viewer
      eza # Modern ls replacement
      fd # Fast file finder
      fzf # Fuzzy finder
      git # Version control
      nixfmt-rfc-style # Nix formatter
      nix-prefetch-scripts # Tools to get hashes for nix derivations (used in zsh.nix module)
      starship # Shell prompt
      iptables # Firewall utility
      wget # Downloader
      curl # Downloader

      # --- SYSTEM TOOLS ---
      autotrash # Automatic trash cleanup
      distrobox # Container system for dev environments
      foot # Tiny, zero-config terminal (Rescue tool)
      glib # Low-level system library
      gsettings-desktop-schemas # Global theme settings
      libnotify # Library for desktop notifications (used by most de/wm modules)
      polkit_gnome # Authentication agent
      sops # Secret management
      shellPkg # The selected shell package (bash, zsh, or fish)
      xdg-desktop-portal-gtk # GTK portal backend for file pickers
      wvkbd # Virtual keyboard (for Wayland)

      # --- GRAPHICS & GUI SUPPORT ---
      gtk3 # Standard GUI toolkit
      libsForQt5.qt5.qtwayland # Qt5 Wayland bridge
      kdePackages.qtwayland # Qt6 Wayland bridge
      powerline-symbols # Terminal font glyphs
    ]
    # Installation of packages available only on x86_64 systems
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux")
    (builtins.trace
      "✅ x86_64 Architecture Detected: Installing x86 only packages"
      [ gpu-screen-recorder ])

    # Extra KDE specific packages
    ++ (with pkgs.kdePackages; [
      gwenview # Default image viewer as defined in mime.nix
      kio-extras # Extra protocols for KDE file dialogs (needed for dolphin remote access)
      kio-fuse # Mount remote filesystems (via ssh, ftp, etc.) in Dolphin
    ])

    # Extra packages from unstable channel
    ++ (with pkgs-unstable; [ ]);

  # ---------------------------------------------------------
  # 🎨 FONTS
  # ---------------------------------------------------------
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # Primary monospace font (coding/terminal)
    nerd-fonts.symbols-only # Icon fallback
    noto-fonts # "No Tofu" standard
    dejavu_fonts # Core Linux fallback
    noto-fonts-lgc-plus # Extended European/Greek/Cyrillic
    noto-fonts-color-emoji # Color emojis
    noto-fonts-cjk-sans # Asian language support (Chinese/Japanese/Korean)
    texlivePackages.hebrew-fonts # Hebrew support
    font-awesome # System icons (Waybar/Bar)
    powerline-fonts # Shell prompt glyphs
  ];
  fonts.fontconfig.enable = true;

  # ---------------------------------------------------------
  # 🛡️ SECURITY & WRAPPERS
  # ---------------------------------------------------------
  security.rtkit.enable = true;
  services.openssh.enable = true;

  # Only define these wrappers if we are on an x86 system.
  security.wrappers =
    lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      gpu-screen-recorder = {
        owner = "root";
        group = "root";
        capabilities = "cap_sys_admin+ep";
        source = "${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder";
      };
      gsr-kms-server = {
        owner = "root";
        group = "root";
        capabilities = "cap_sys_admin+ep";
        source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
      };
    };

  # Use optionalString to inject the GPU rule ONLY on x86.
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        // Auto-approve realtime audio requests (Keep this for everyone)
        if (action.id == "org.freedesktop.RealtimeKit1.acquire-high-priority" ||
            action.id == "org.freedesktop.RealtimeKit1.acquire-real-time") {
          return polkit.Result.YES;
        }

        ${
          lib.optionalString
          (pkgs.stdenv.hostPlatform.system == "x86_64-linux") ''
            // Auto-approve gpu-screen-recorder running as root (x86 ONLY)
            if (action.id == "org.freedesktop.policykit.exec" &&
                action.lookup("program") &&
                action.lookup("program").indexOf("gpu-screen-recorder") > -1) {
              return polkit.Result.YES;
            }
          ''
        }
      }
    });
  '';

  # ---------------------------------------------------------
  # 🐚 SHELLS & ENVIRONMENT
  # ---------------------------------------------------------
  programs.zsh.enable = vars.shell == "zsh";
  programs.fish.enable = vars.shell == "fish";

  # -----------------------------------------------------
  # 🎨 GLOBAL THEME VARIABLES
  # -----------------------------------------------------
  environment.variables.GTK_APPLICATION_PREFER_DARK_THEME =
    if vars.polarity == "dark" then "1" else "0";

  # -----------------------------------------------------
  # ⚡ SYSTEM TWEAKS
  # -----------------------------------------------------
  # Reduce shutdown wait time for stuck services
  systemd.settings.Manager = { DefaultTimeoutStopSec = "10s"; };

  # Enable home-manager backup files
  home-manager.backupFileExtension = lib.mkForce "hm-backup";

  # Enable UPower for better power management and battery reporting (needed for noctalia shell)
  services.upower.enable = true;

  # Enable the modern power-profiles-daemon (needed for noctalia shell)
  services.power-profiles-daemon.enable = true;

  # Enable System76 Scheduler for improved desktop responsiveness
  services.system76-scheduler.enable = true;
  services.system76-scheduler.settings.cfsProfiles.enable =
    true; # Prioritizes foreground apps (smoothness)

  # Disable NetworkManager-wait-online to speed up boot time
  systemd.services.NetworkManager-wait-online.enable = false;

  # Enable emulation for aarch64 linux for testing purposes on x86_64 hosts
  boot.binfmt.emulatedSystems =
    lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux")
    [ "aarch64-linux" ];

  # Add KWallet integration for SDDM and GDM display managers
  security.pam.services = {
    sddm.enableKwallet = config.services.displayManager.sddm.enable;
    gdm.enableKwallet = config.services.displayManager.gdm.enable;
  };

  # Explicitly disable TLP to avoid conflicts
  services.tlp.enable = false;
}
