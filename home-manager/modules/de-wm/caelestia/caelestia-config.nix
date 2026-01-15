{ vars, ... }:
let
  isTerminalFM =
    fm:
    builtins.elem fm [
      "ranger"
      "yazi"
      "lf"
      "nnn"
      "mc"
    ];

  explorerCmd =
    if isTerminalFM vars.fileManager then
      [
        vars.term
        "-e"
        vars.fileManager
      ]
    else
      [ vars.fileManager ];
in
{
  dashboard = {
    sizes = {
      resourceProgessThickness = 10;
      infoIconSize = 25;
      mediaProgressThickness = 8;
      mediaCoverArtSize = 150;
      tabIndicatorHeight = 3;
      mediaWidth = 200;
      dateTimeWidth = 110;
      infoWidth = 200;
      mediaProgressSweep = 180;
      mediaVisualiserSize = 80;
      tabIndicatorSpacing = 5;
      resourceSize = 200;
      weatherWidth = 250;
    };
    showOnHover = true;
    enabled = true;
    mediaUpdateInterval = 500;
    dragThreshold = 50;
  };

  paths = {
    sessionGif = "root:/assets/kurukuru.gif";
    mediaGif = "root:/assets/bongocat.gif";
    wallpaperDir = "/home/${vars.user}/Pictures/Wallpapers";
  };

  bar = {
    status = {
      showBluetooth = true;
      showBattery = true;
      showNetwork = true;
      showKbLayout = true;
      showLockStatus = true;
      showAudio = true;
      showMicrophone = true;
    };
    sizes = {
      innerWidth = 40;
      networkWidth = 320;
      windowPreviewSize = 400;
      trayMenuWidth = 300;
      batteryWidth = 250;
    };
    dragThreshold = 20;
    entries = [
      {
        enabled = true;
        id = "logo";
      }
      {
        enabled = true;
        id = "workspaces";
      }
      {
        enabled = true;
        id = "spacer";
      }
      {
        enabled = true;
        id = "activeWindow";
      }
      {
        enabled = true;
        id = "spacer";
      }
      {
        enabled = true;
        id = "tray";
      }
      {
        enabled = true;
        id = "clock";
      }
      {
        enabled = true;
        id = "statusIcons";
      }
      {
        enabled = true;
        id = "power";
      }
    ];
    persistent = true;
    tray = {
      iconSubs = [ ];
      recolour = false;
      compact = true;
      background = true;
    };
    scrollActions = {
      volume = true;
      workspaces = true;
      brightness = true;
    };
    popouts = {
      tray = true;
      statusIcons = true;
      activeWindow = true;
    };
    showOnHover = true;
    workspaces = {
      showWindowsOnSpecialWorkspaces = true;
      perMonitorWorkspaces = true;
      label = "  ";
      occupiedBg = false;
      capitalisation = "preserve";
      specialWorkspaceIcons = [ ];
      activeIndicator = true;
      showWindows = true;
      activeTrail = false;
      occupiedLabel = "󰮯";
      shown = 5;
      activeLabel = "󰮯";
    };
    clock = {
      showIcon = true;
    };
  };

  utilities = {
    sizes = {
      width = 430;
      toastWidth = 430;
    };
    enabled = true;
    maxToasts = 4;
    toasts = {
      audioOutputChanged = true;
      kbLayoutChanged = true;
      nowPlaying = false;
      gameModeChanged = true;
      dndChanged = true;
      vpnChanged = true;
      chargingChanged = true;
      configLoaded = true;
      audioInputChanged = true;
      capsLockChanged = true;
      numLockChanged = true;
    };
    vpn = {
      enabled = false;
      provider = [ "openvpn" ];
    };
  };

  osd = {
    hideDelay = 2000;
    sizes = {
      sliderWidth = 30;
      sliderHeight = 150;
    };
    enabled = true;
    enableBrightness = true;
    enableMicrophone = false;
  };

  session = {
    sizes = {
      button = 80;
    };
    vimKeybinds = true;
    enabled = true;
    dragThreshold = 30;
    commands = {
      logout = [
        "/run/current-system/sw/bin/uwsm"
        "stop"
      ];
      shutdown = [
        "systemctl"
        "poweroff"
      ];
      hibernate = [
        "systemctl"
        "hibernate"
      ];
      reboot = [
        "systemctl"
        "reboot"
      ];
    };
  };

  general = {
    apps = {
      explorer = explorerCmd;
      audio = [ "pavucontrol" ];
      playback = [ "mpv" ];
      terminal = [ "${vars.term}" ];
    };
    idle = {
      timeouts =
        if (vars.idleConfig.enable or true) then
          [
            {
              idleAction = "lock";
              timeout = vars.idleConfig.lockTimeout or 300;
            }
            {
              idleAction = "dpms off";
              returnAction = "dpms on";
              timeout = vars.idleConfig.screenOffTimeout or 600;
            }
            {
              idleAction = [
                "systemctl"
                "suspend"
              ];
              timeout = vars.idleConfig.suspendTimeout or 600;
            }
          ]
        else
          [ ];
      lockBeforeSleep = true;
      inhibitWhenAudio = true;
    };
    battery = {
      warnLevels = [
        {
          message = "You might want to plug in a charger";
          icon = "battery_android_frame_2";
          level = 20;
          title = "Low battery";
        }
        {
          message = "You should probably plug in a charger <b>now</b>";
          icon = "battery_android_frame_1";
          level = 10;
          title = "Did you see the previous message?";
        }
        {
          critical = true;
          message = "PLUG THE CHARGER RIGHT NOW!!";
          icon = "battery_android_alert";
          level = 5;
          title = "Critical battery level";
        }
      ];
      criticalLevel = 3;
    };
  };

  background = {
    enabled = false;
    visualiser = {
      autoHide = true;
      rounding = 1;
      enabled = false;
      blur = false;
      spacing = 1;
    };
    desktopClock = {
      enabled = false;
    };
  };

  border = {
    rounding = 25;
    thickness = 10;
  };

  controlCenter = {
    sizes = {
      ratio = 1.7777777777777777;
      heightMult = 0.7;
    };
  };

  appearance = {
    rounding = {
      scale = 1;
    };
    transparency = {
      enabled = false;
      base = 0.85;
      layers = 0.4;
    };
    anim = {
      durations = {
        scale = 1;
      };
    };
    padding = {
      scale = 1;
    };
    font = {
      size = {
        scale = 1;
      };
      family = {
        material = "Material Symbols Rounded";
        mono = "CaskaydiaCove NF";
        sans = "Rubik";
        clock = "Rubik";
      };
    };
    spacing = {
      scale = 1;
    };
  };

  notifs = {
    expire = true;
    clearThreshold = 0.3;
    expandThreshold = 20;
    actionOnClick = false;
    defaultExpireTimeout = 5000;
    groupPreviewNum = 3;
    sizes = {
      width = 400;
      image = 41;
      badge = 20;
    };
  };

  winfo = {
    sizes = {
      detailsWidth = 500;
      heightMult = 0.7;
    };
  };

  lock = {
    sizes = {
      ratio = 1.7777777777777777;
      centerWidth = 600;
      heightMult = 0.7;
    };
    recolourLogo = false;
    enableFprint = true;
    maxFprintTries = 3;
  };

  launcher = {
    actions = [
      {
        name = "Calculator";
        dangerous = false;
        enabled = true;
        description = "Do simple math equations (powered by Qalc)";
        command = [
          "autocomplete"
          "calc"
        ];
        icon = "calculate";
      }
      {
        name = "Scheme";
        dangerous = false;
        enabled = false;
        description = "Change the current colour scheme";
        command = [
          "autocomplete"
          "scheme"
        ];
        icon = "palette";
      }
      {
        name = "Wallpaper";
        dangerous = false;
        enabled = false;
        description = "Change the current wallpaper";
        command = [
          "autocomplete"
          "wallpaper"
        ];
        icon = "image";
      }
      {
        name = "Variant";
        dangerous = false;
        enabled = false;
        description = "Change the current scheme variant";
        command = [
          "autocomplete"
          "variant"
        ];
        icon = "colors";
      }
      {
        name = "Transparency";
        dangerous = false;
        enabled = false;
        description = "Change shell transparency";
        command = [
          "autocomplete"
          "transparency"
        ];
        icon = "opacity";
      }
      {
        name = "Random";
        dangerous = false;
        enabled = false;
        description = "Switch to a random wallpaper";
        command = [
          "caelestia"
          "wallpaper"
          "-r"
        ];
        icon = "casino";
      }
      {
        name = "Light";
        dangerous = false;
        enabled = false;
        description = "Change the scheme to light mode";
        command = [
          "setMode"
          "light"
        ];
        icon = "light_mode";
      }
      {
        name = "Dark";
        dangerous = false;
        enabled = false;
        description = "Change the scheme to dark mode";
        command = [
          "setMode"
          "dark"
        ];
        icon = "dark_mode";
      }
      {
        name = "Shutdown";
        dangerous = true;
        enabled = true;
        description = "Shutdown the system";
        command = [
          "systemctl"
          "poweroff"
        ];
        icon = "power_settings_new";
      }
      {
        name = "Reboot";
        dangerous = true;
        enabled = true;
        description = "Reboot the system";
        command = [
          "systemctl"
          "reboot"
        ];
        icon = "cached";
      }
      {
        name = "Logout";
        dangerous = true;
        enabled = true;
        description = "Log out of the current session";
        command = [
          "/run/current-system/sw/bin/uwsm"
          "stop"
        ];
        icon = "exit_to_app";
      }
      {
        name = "Lock";
        dangerous = false;
        enabled = true;
        description = "Lock the current session";
        command = [
          "loginctl"
          "lock-session"
        ];
        icon = "lock";
      }
      {
        name = "Sleep";
        dangerous = false;
        enabled = true;
        description = "Suspend then hibernate";
        command = [
          "systemctl"
          "suspend-then-hibernate"
        ];
        icon = "bedtime";
      }
    ];
    maxShown = 7;
    showOnHover = true;
    actionPrefix = ">";
    dragThreshold = 50;
    vimKeybinds = true;
    enableDangerousActions = true;
    specialPrefix = "@";
    hiddenApps = [ ];
    enabled = true;
    useFuzzy = {
      schemes = true;
      apps = true;
      actions = true;
      variants = true;
      wallpapers = false;
    };
    maxWallpapers = 9;
    sizes = {
      wallpaperWidth = 280;
      itemWidth = 600;
      itemHeight = 57;
      wallpaperHeight = 200;
    };
  };

  sidebar = {
    enabled = true;
    sizes = {
      width = 430;
    };
    dragThreshold = 80;
  };

  services = {
    useFahrenheit = vars.useFahrenheit or false;
    useTwelveHourClock = true;
    weatherLocation = vars.weather;
    gpuType = "";
    playerAliases = [
      {
        to = "YT Music";
        from = "com.github.th_ch.youtube_music";
      }
    ];
    visualiserBars = 45;
    maxVolume = 1;
    defaultPlayer = "";
    audioIncrement = 0.1;
    smartScheme = true;
  };
}
