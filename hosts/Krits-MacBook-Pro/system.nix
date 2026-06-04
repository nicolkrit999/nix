{ delib
, inputs
, config
, ...
}:
delib.host {
  name = "Krits-MacBook-Pro";

  darwin = {
    nixpkgs.hostPlatform = "aarch64-darwin";
    nixpkgs.config.allowUnfree = true;

    system.primaryUser = "krit";

    imports = [
      inputs.nix-sops.darwinModules.sops
    ];

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # 🔐 SOPS CONFIGURATION
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    environment.variables = {
      SOPS_AGE_KEY_FILE = "/Users/krit/.config/sops/age/keys.txt";
    };

    sops.defaultSopsFile = ./Krits-MacBook-Pro-secrets-sops.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.keyFile = "/Users/krit/.config/sops/age/keys.txt";
    sops.environment.SOPS_AGE_KEY_FILE = "/Users/krit/.config/sops/age/keys.txt";
    sops.age.sshKeyPaths = [ ];
    sops.gnupg.sshKeyPaths = [ ];

    # Common sops secrets live in users/krit/common/toplevel/sops-secrets.nix
    # (enabled via this host's default.nix). Host-specific secrets, if any,
    # would go here.

    nix.extraOptions = ''
      !include ${config.sops.secrets.github_fg_pat_token_nix.path}
    '';

    # -----------------------------------------------------------------------
    # 🍎 MAC APP STORE APPS
    # -----------------------------------------------------------------------
    homebrew.masApps = {
      #"HP Print" = 1474276998;
      "DaVinci Resolve" = 571213070;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
    };

    # -----------------------------------------------------------------------
    # ⚙️ SYSTEM DEFAULTS
    # -----------------------------------------------------------------------
    system.defaults = {
      dock = {
        autohide = true;
        launchanim = true;
        static-only = false;
        show-recents = false;
        show-process-indicators = true;
        orientation = "bottom";
        tilesize = 50;
        minimize-to-application = true;
        mineffect = "scale";
        persistent-apps = [
          "/System/Applications/Apps.app"
          "/Applications/Comet.app"
          "/Users/krit/Applications/Home Manager Apps/Firefox.app"
          "/Users/krit/Applications/Home Manager Apps/kitty.app"
          "/Applications/WhatsApp.app"
          "/System/Applications/Music.app"
          "/Applications/UGREEN NAS.app"
          "/Applications/Proton Pass.app"
          "/Applications/Discord.app"
          "/Users/krit/Applications/Home Manager Apps/Visual Studio Code.app"
          "/Applications/GitHub Desktop.app"
          "/Users/krit/Applications/JetKVM.app"
          "/System/Applications/Calendar.app"
        ];
      };

      finder = {
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = true;
        ShowRemovableMediaOnDesktop = true;
        _FXSortFoldersFirst = true;
        FXDefaultSearchScope = "SCcf";
        NewWindowTarget = "Desktop";
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = true;
        ShowStatusBar = true;
        ShowPathbar = true;
        FXPreferredViewStyle = "Nlsv";
      };

      NSGlobalDomain = {
        AppleShowScrollBars = "Always";
        NSUseAnimatedFocusRing = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        NSDocumentSaveNewDocumentsToCloud = false;
        ApplePressAndHoldEnabled = false;
        InitialKeyRepeat = 25;
        KeyRepeat = 2;
        "com.apple.mouse.tapBehavior" = 1;
        NSWindowShouldDragOnGesture = true;
        NSAutomaticSpellingCorrectionEnabled = false;
      };

      CustomUserPreferences = {
        "com.apple.finder" = {
          WarnOnEmptyTrash = true;
        };
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.dock" = {
          enable-window-tool = false;
        };
        "com.apple.ActivityMonitor" = {
          OpenMainWindow = true;
          IconType = 5;
          SortColumn = "CPUUsage";
          SortDirection = 0;
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          ScheduleFrequency = 1;
          AutomaticDownload = 1;
          CriticalUpdateInstall = 1;
        };
      };
    };
  };
}
