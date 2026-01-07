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
  # home.nix and host-modules are imported from flake.nix
  imports = [
    # Hardware scan (auto-generated)
    ./hardware-configuration.nix

    # Packages specific to this machine
    ./optional/host-packages/default.nix

    # Core imports
    ../../nixos/modules/core.nix
  ];

  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # 🔐 SOPS CONFIGURATION
  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  /*
    sops.defaultSopsFile = ./optional/host-sops-nix/secrets.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  */

  hardware.graphics.enable = true; # Keep enabled to avoid terminal crash when disabling certain de

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    noto-fonts
    dejavu_fonts
    noto-fonts-lgc-plus
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    texlivePackages.hebrew-fonts
    font-awesome
    powerline-fonts
  ];

  fonts.fontconfig.enable = true;

  environment.systemPackages = with pkgs; [
    foot
    iptables
    glib
    gsettings-desktop-schemas
    gtk3
    libsForQt5.qt5.qtwayland
    kdePackages.qtwayland
    powerline-symbols
    polkit_gnome
  ];

  programs.dconf.enable = true;

  programs.zsh.enable = true;

  security.wrappers.gpu-screen-recorder = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+ep";
    source = "${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder";
  };

  # ---------------------------------------------------------
  # 🖥️ HOST IDENTITY
  # ---------------------------------------------------------
  # Dynamically sets the hostname passed from flake.nix
  networking.hostName = hostname;

  # Enable networking
  networking.networkmanager.enable = true;

  # ---------------------------------------------------------
  # ⚔️ STABILITY FIX: Force 'Switch User' to act as 'Log Out'
  # ---------------------------------------------------------
  # This was done mainly to help the guest user to be kicked out from unauthorized sessions
  systemd.tmpfiles.rules = [
    "f /etc/systemd/logind.conf.d/10-logout-override.conf 0644 root root - [Login]\nKillUserProcesses=yes\nIdleAction=none\n"
  ];

  # ---------------------------------------------------------
  # ⌨️ KEYBOARD LAYOUT (Global Logic)
  # ---------------------------------------------------------
  # Applies the layout defined in flake.nix to X11, Wayland, and Console.
  # This ensures that all the desktop environments and TTYs use the same layout.
  services.xserver.xkb = {
    layout = keyboardLayout;
    variant = keyboardVariant;
  };

  # Forces the text console (TTY) to look at the Xserver settings above.
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
  # Defines the user dynamically based on flake.nix input
  users.users.${user} = {
    isNormalUser = true;
    description = "Primary user";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      #"docker"
      "video"
      "audio"
    ];
    shell = pkgs.zsh; # Ensure zsh is installed in system packages
  };

  # This is needed if you want to use docker and be part of the docker group
  #virtualisation.docker.enable = true;

  # Nix Settings (Flakes & Garbage Collection)
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Defines the state version dynamically based on flake.nix input
  system.stateVersion = stateVersion;

  i18n.inputMethod.enabled = lib.mkForce null;
  environment.variables.GTK_IM_MODULE = lib.mkForce "";
  environment.variables.QT_IM_MODULE = lib.mkForce "";
  environment.variables.XMODIFIERS = lib.mkForce "";
}
