{ delib
, inputs
, pkgs
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

    sops.secrets =
      let
        commonSecrets = ../../users/krit/common/sops/krit-common-secrets-sops.yaml;
      in
      {
        github_fg_pat_token_nix = {
          sopsFile = commonSecrets;
          mode = "0444";
        };
        github_general_ssh_key = {
          sopsFile = commonSecrets;
          owner = "krit";
          path = "/Users/krit/.ssh/id_github";
          mode = "0600";
        };
        github_general_ssh_pub = {
          sopsFile = commonSecrets;
          owner = "krit";
          path = "/Users/krit/.ssh/id_github.pub";
          mode = "0644";
        };
        school_ssh_key = {
          sopsFile = commonSecrets;
          owner = "krit";
          path = "/Users/krit/.ssh/id_school";
          mode = "0600";
        };
        school_ssh_pub = {
          sopsFile = commonSecrets;
          owner = "krit";
          path = "/Users/krit/.ssh/id_school.pub";
          mode = "0644";
        };
        Krit_Wifi_pass = {
          sopsFile = commonSecrets;
        };
        Nicol_5Ghz_pass = {
          sopsFile = commonSecrets;
        };
        Nicol_2Ghz_pass = {
          sopsFile = commonSecrets;
        };
        openrouter_api_claude_code = {
          sopsFile = commonSecrets;
          owner = "krit";
        };
        claude_mcp_actual_password = {
          sopsFile = commonSecrets;
          owner = "krit";
        };
        claude_mcp_actual_sync_id = {
          sopsFile = commonSecrets;
          owner = "krit";
        };
        claude_mcp_actual_encryption_password = {
          sopsFile = commonSecrets;
          owner = "krit";
        };
        claude_mcp_context7_api_key = {
          sopsFile = commonSecrets;
          owner = "krit";
        };
        claude_mcp_openai_api_key = {
          sopsFile = commonSecrets;
          owner = "krit";
        };
        claude_mcp_milvus_token = {
          sopsFile = commonSecrets;
          owner = "krit";
        };
        claude_mcp_github_token = {
          sopsFile = commonSecrets;
          owner = "krit";
        };
        claude_mcp_portainer_token = {
          sopsFile = commonSecrets;
          owner = "krit";
        };
      };

    nix.extraOptions = ''
      !include ${config.sops.secrets.github_fg_pat_token_nix.path}
    '';

    environment.systemPackages = with pkgs; [
      gnupg
      pinentry_mac
    ];

    # -----------------------------------------------------------------------
    # 🍎 MAC APP STORE APPS
    # -----------------------------------------------------------------------
    homebrew.masApps = {
      "HP Print" = 1474276998;
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
          "/Applications/Firefox.app"
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
