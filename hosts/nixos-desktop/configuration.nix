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
    (
      if builtins.pathExists "/etc/nixos/secrets/borg-passphrase" then
        ./host-modules/borg-backup.nix
      else
        null
    )

  ];

  # ---------------------------------------------------------
  # ⚙️ GRAPHICS & FONTS
  # ---------------------------------------------------------
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.graphics.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # Primary monospace font; includes icons for coding and terminal use
    nerd-fonts.symbols-only # Icon fallback; ensures symbols render even when the main font lacks them
    noto-fonts # Base text coverage; Google's "No Tofu" standard to fix square boxes globally
    dejavu_fonts # Core Linux fallback; high compatibility for standard text in older apps
    noto-fonts-lgc-plus # Extended European support; covers complex Latin, Greek, and Cyrillic variants
    noto-fonts-color-emoji # Emoji support; ensures emojis appear in color rather than monochrome outlines
    noto-fonts-cjk-sans # Asian language support; mandatory for Chinese, Japanese, and Korean characters
    texlivePackages.hebrew-fonts # Hebrew support; specialized font for correct Hebrew script rendering
    font-awesome # System icons; standard dependency for Waybar and desktop interface elements
    powerline-fonts # Shell prompt glyphs; prevents broken triangles/shapes in Zsh/Bash prompts
  ];

  fonts.fontconfig.enable = true;

  # ---------------------------------------------------------
  # 📦 SYSTEM PACKAGES
  # ---------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # Tiny, zero-config terminal; critical rescue tool if your main terminal config breaks
    foot
    iptables # Core firewall utility; base dependency for network security and containers
    glib # Low-level system library; almost all software crashes without this base layer
    gpu-screen-recorder # Used for caelestia and included here to ensure proper permissions
    # Global theme settings; prevents GTK apps from looking broken or crashing
    gsettings-desktop-schemas
    gtk3 # Standard GUI toolkit; essential for drawing basic application windows
    libsForQt5.qt5.qtwayland # Qt5 Wayland bridge; mandatory for older Qt apps to display correctly
    kdePackages.qtwayland # Qt6 Wayland bridge; mandatory for modern Qt apps to display correctly
    powerline-symbols # Terminal font glyphs; prevents "box" errors in shell prompts
    polkit_gnome # Authentication agent; required for GUI apps (like Btrfs Assistant) to ask for passwords

  ];

  programs.dconf.enable = true;
  programs.zsh.enable = true;

  security.wrappers.gpu-screen-recorder = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+ep";
    source = "${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder";
  };

  security.wrappers.gsr-kms-server = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+ep";
    source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
  };

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
  # 🛡️ SECURITY & REALTIME AUDIO
  # ---------------------------------------------------------
  security.rtkit.enable = true;

  # Allow members of "wheel" to:
  # 1. Get realtime audio priority (fixes audio recording prompt)
  # 2. Run commands as root via pkexec (fixes gpu-screen-recorder prompt)
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        // Auto-approve realtime audio requests
        if (action.id == "org.freedesktop.RealtimeKit1.acquire-high-priority" ||
            action.id == "org.freedesktop.RealtimeKit1.acquire-real-time") {
          return polkit.Result.YES;
        }
        
        // Auto-approve gpu-screen-recorder running as root
        // (Caelestia uses pkexec to launch it)
        if (action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("program") && 
            action.lookup("program").indexOf("gpu-screen-recorder") > -1) {
          return polkit.Result.YES;
        }
      }
    });
  '';

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
