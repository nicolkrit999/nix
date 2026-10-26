{ delib
, config
, ...
}:
let
  home = config.users.users.${config.myconfig.constants.user}.home;
  ageKeyFile = "${home}/.config/sops/age/keys.txt";
in
delib.host {
  name = "Krits-MacBook-Pro";

  darwin = {
    nixpkgs.hostPlatform = "aarch64-darwin";
    # tied to the original install (stateVersion 4); the nix-darwin default would be 30000
    ids.gids.nixbld = 350;

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # 🔐 SOPS CONFIGURATION
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    environment.variables.SOPS_AGE_KEY_FILE = ageKeyFile;

    sops = {
      defaultSopsFile = ./Krits-MacBook-Pro-secrets-sops.yaml;
      defaultSopsFormat = "yaml";
      age = {
        keyFile = ageKeyFile;
        sshKeyPaths = [ ];
      };
      gnupg.sshKeyPaths = [ ];
      environment.SOPS_AGE_KEY_FILE = ageKeyFile;
    };

    # Common sops secrets live in users/krit/common/toplevel/sops-secrets.nix
    # (enabled via this host's default.nix). The host yaml holds borg-passphrase
    # and borg-private-key, resolved through defaultSopsFile.

    nix.extraOptions = ''
      !include ${config.sops.secrets.github_fg_pat_token_nix.path}
    '';

    # -----------------------------------------------------------------------
    # 🍎 MAC APP STORE APPS
    # -----------------------------------------------------------------------
    # Disabled: mas 7.0.0 breaks `brew bundle` (see memory project_masapps_mas7_disabled).
    # Re-enable once homebrew-bundle supports mas 7.x.
    # homebrew.masApps = {
    #   #"HP Print" = 1474276998;
    #   "DaVinci Resolve" = 571213070;
    #   "Keynote" = 409183694;
    #   "Numbers" = 409203825;
    #   "Pages" = 409201541;
    # };

    # -----------------------------------------------------------------------
    # ⚙️ SYSTEM DEFAULTS
    # -----------------------------------------------------------------------
    system.defaults = {
      dock = {
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
          "${home}/Applications/Home Manager Apps/kitty.app"
          "/Applications/WhatsApp.app"
          "/System/Applications/Music.app"
          "/Applications/UGREEN NAS.app"
          "/Applications/Proton Pass.app"
          "${home}/Applications/Home Manager Apps/Discord.app"
          "/Applications/Nix Apps/Visual Studio Code.app"
          "/Applications/GitHub Desktop.app"
          "${home}/Applications/JetKVM.app"
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

      ActivityMonitor = {
        OpenMainWindow = true;
        IconType = 5;
        SortColumn = "CPUUsage";
        SortDirection = 0;
      };

      # System-domain key needs the full path; not verifiable without a Mac.
      CustomSystemPreferences."/Library/Preferences/com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        ScheduleFrequency = 1;
        AutomaticDownload = 1;
        CriticalUpdateInstall = 1;
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
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
      };
    };
  };
}
