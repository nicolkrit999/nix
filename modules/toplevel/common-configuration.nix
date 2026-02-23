{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "common-configuration";

  nixos.always =
    {
      myconfig,
      ...
    }:
    let
      currentShell = myconfig.constants.shell or "zsh";

      shellPkg =
        if currentShell == "fish" then
          pkgs.fish
        else if currentShell == "zsh" then
          pkgs.zsh
        else
          pkgs.bashInteractive;
    in
    {
      # ---------------------------------------------------------
      # 🖥️ HOST IDENTITY
      # ---------------------------------------------------------
      networking.hostName = myconfig.constants.hostname;
      networking.networkmanager.enable = true;
      system.stateVersion = myconfig.constants.stateVersion or "25.11";

      # ---------------------------------------------------------
      # 🌍 LOCALE & TIME
      # ---------------------------------------------------------
      time.timeZone = myconfig.constants.timeZone or "Etc/UTC";

      # Keyboard Layout
      services.xserver.xkb = {
        layout = myconfig.constants.keyboardLayout or "us";
        variant = myconfig.constants.keyboardVariant or "";
      };
      console.useXkbConfig = true;

      # ---------------------------------------------------------
      # 🛠️ NIX SETTINGS
      # ---------------------------------------------------------
      nix.settings = {
        trusted-users = [
          "root"
          "@wheel"
        ];
        extra-platforms = [ "aarch64-linux" ]; # Accept aarch64-linux derivations
      };

      # Gpu screen recorder overlay due to missing ARM support in the main package
      nixpkgs.overlays = [
        (final: prev: {
          gpu-screen-recorder =
            if prev.stdenv.hostPlatform.system == "aarch64-linux" then
              prev.symlinkJoin {
                name = "gpu-screen-recorder-dummy";
                paths = [
                  (prev.writeShellScriptBin "gpu-screen-recorder" "echo 'GPU Screen Recorder is not supported on ARM'")
                  (prev.writeShellScriptBin "gsr-kms-server" "echo 'Not supported'")
                ];
              }
            else
              prev.gpu-screen-recorder;
        })
      ];

      # Allow unfree packages globally (needed for drivers, code, etc.)
      nixpkgs.config.allowUnfree = true;

      # ---------------------------------------------------------
      # 📦 SYSTEM PACKAGES
      # ---------------------------------------------------------
      environment.systemPackages =
        with pkgs;
        [
          # --- CLI UTILITIES ---
          dix # Nix diff viewer
          git # Version control
          nixfmt # Nix formatter
          nix-prefetch-scripts # Tools to get hashes for nix derivations (used in every shell modules)
          wget # Downloader
          curl # Downloader

          # --- SYSTEM TOOLS ---
          foot # Tiny, zero-config terminal (Rescue tool)
          gsettings-desktop-schemas # Global theme settings
          libnotify # Library for desktop notifications (used by most de/wm modules)
          polkit_gnome # Authentication agent, forced in every de/wm
          seahorse # GNOME key and password manager
          sops # Secret management
          shellPkg # The selected shell package (bash, zsh, or fish)
          xdg-desktop-portal-gtk # GTK portal backend for file pickers

          # --- GRAPHICS & GUI SUPPORT ---
          gtk3 # Standard GUI toolkit
          libsForQt5.qt5.qtwayland # Qt5 Wayland bridge
          kdePackages.qtwayland # Qt6 Wayland bridge
        ]
        ++ (with pkgs.kdePackages; [
          gwenview # Default image viewer as defined in mime.nix
        ])

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
        powerline-symbols # Terminal font glyphs
      ];
      fonts.fontconfig.enable = true;

      # ---------------------------------------------------------
      # 🛡️ SECURITY & WRAPPERS
      # ---------------------------------------------------------
      security.rtkit.enable = true;
      services.openssh.enable = true;

      # Polkit Rules: Realtime Audio & GPU Recorder Permissions
      security.polkit.enable = true;

      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel")) {
            // Auto-approve realtime audio requests
            if (action.id == "org.freedesktop.RealtimeKit1.acquire-high-priority" ||
                action.id == "org.freedesktop.RealtimeKit1.acquire-real-time") {
              return polkit.Result.YES;
            }
            // Auto-approve gpu-screen-recorder running as root
            if (action.id == "org.freedesktop.policykit.exec" &&
                action.lookup("program") &&
                action.lookup("program").indexOf("gpu-screen-recorder") > -1) {
              return polkit.Result.YES;
            }
          }
        });
      '';

      # Keyrings & Wallets
      # Globally enable GNOME Keyring
      services.gnome.gnome-keyring.enable = true;

      # Disable KWallet to avoid conflicts with GNOME Keyring
      # TODO: check if this really work. IF not must be improved to avoid conflicts when both gnome and kde are enabled
      security.pam.services.login.enableGnomeKeyring = true;
      security.pam.services.sddm.enableGnomeKeyring = true;
      security.pam.services.login.enableKwallet = lib.mkForce false;
      security.pam.services.kde.enableKwallet = lib.mkForce false;
      security.pam.services.sddm.enableKwallet = lib.mkForce false;

      # ---------------------------------------------------------
      # 🐚 SHELLS & ENVIRONMENT
      # ---------------------------------------------------------
      programs.zsh.enable = currentShell == "zsh";
      programs.fish.enable = currentShell == "fish";

      i18n.inputMethod.enabled = lib.mkForce null;
      environment.variables.GTK_IM_MODULE = lib.mkForce "";
      environment.variables.QT_IM_MODULE = lib.mkForce "";
      environment.variables.XMODIFIERS = lib.mkForce "";

      # -----------------------------------------------------
      # 🎨 GLOBAL THEME VARIABLES
      # -----------------------------------------------------
      environment.variables.GTK_APPLICATION_PREFER_DARK_THEME =
        if myconfig.constants.theme.polarity == "dark" then "1" else "0";

      # -----------------------------------------------------
      # ⚡ SYSTEM TWEAKS
      # -----------------------------------------------------
      # Reduce shutdown wait time for stuck services
      systemd.settings.Manager = {
        DefaultTimeoutStopSec = "10s";
      };

      # Enable home-manager backup files extension
      home-manager.backupFileExtension = lib.mkForce "hm-backup";

    };
}
