{
  pkgs,
  lib,
  vars,
  ...
}:
{

  imports = [
    ./init-lua.nix
  ];

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    plugins = {
      ouch = pkgs.fetchFromGitHub {
        owner = "ndtoan96";
        repo = "ouch.yazi";
        rev = "cfb9140";
        sha256 = "sha256-6TyKPsapXJMiSRFrKRfP/hamOiG6LfgbPp7flh5tKoo=";
      };
    };

    # -----------------------------------------------------------------------
    # ⚙️ YAZI.TOML CONFIGURATION
    # -----------------------------------------------------------------------
    settings = {
      mgr = {
        ratio = [
          1
          4
          3
        ];
        sort_by = "alphabetical";
        sort_sensitive = false; # Disable case sensitivity. Keep disabled otherwise the sorting will be weird.
        sort_reverse = false; # true = Z to A, false = A to Z
        sort_dir_first = true; # Directories first
        sort_translit = false; # Disable transliteration (e.g., "ä" to "a")
        linemode = "custom_metadata"; # Custom linemode defined in init-lua.nix
        show_hidden = false; # Show hidden files. They can be viewed by pressing "."
        show_symlink = true; # Show symlink targets if a file is a symlink
        scrolloff = 20; # The number of files to keep above and below the cursor when moving through the file list.
        mouse_events = [
          "click" # Allows single click to select files
          "scroll" # Allows scrolling through the file list
          "drag" # Allows dragging to select multiple files. Some terminals may not support this.
        ];
        title_format = "Yazi: {cwd}";
      };

      preview = {
        wrap = "no"; # Whatever a long text should go in multiple lines
        tab_size = 2;
        max_width = 1920; # Maximum width for preview images
        max_height = 1080; # Maximum height for preview images
        cache_dir = "/home/krit/.cache/yazi";
        image_delay = 20;
        image_filter = "lanczos3"; # Image scaling filter
        image_quality = 90;
        image_preview_method =
          if
            builtins.elem vars.term [
              "kitty"
              "ghostty"
              "konsole"
              "wezterm"
              "rio"
              "iterm2"
            ]
          then
            "kitty"
          else if
            builtins.elem vars.term [
              "foot"
              "blackbox"
            ]
          then
            "sixel"
          else
            "ueberzug";
        ueberzug_scale = 0.66;
        ueberzug_offset = [
          0
          0
          0
          0
        ];
      };

      opener = {
        # run: shell command to run
        # block: wait for the command to finish before returning to Yazi
        # orphan: Keeps the application running even if you close Yazi. This is ideal for GUI apps like VS Code or media players
        # for: restrict the command to a specific OS (linux, macos, windows, unix)

        # Text editor
        edit = [
          {
            run = ''$EDITOR "$@"'';
            desc = "Edit";
            block = true; # Wait for the editor to close before returning to Yazi
            for = "unix";
          }
          {
            run = ''code "%*"'';
            desc = "code";
            orphan = true;
            for = "windows";
          }
          {
            run = ''code -w "%*"'';
            desc = "code (block)";
            block = true;
            for = "windows";
          }
        ];

        # Play media files
        play = [
          {
            run = ''xdg-open "$@"'';
            desc = "Play";
            for = "linux";
          }
          {
            run = ''open "$@"'';
            desc = "Play";
            for = "macos";
          }
          {
            run = ''start "" "%1"'';
            desc = "Play";
            orphan = true;
            for = "windows";
          }
        ];

        # Open media files
        open = [
          {
            run = ''xdg-open "$@"'';
            desc = "Open";
            for = "linux";
          }
          {
            run = ''open "$@"'';
            desc = "Open";
            for = "macos";
          }
          {
            run = ''start "" "%1"'';
            desc = "Open";
            orphan = true;
            for = "windows";
          }
        ];

        # Open folder in file manager (separate window)
        reveal = [
          {
            run = ''xdg-open "''$(dirname "''$1")"'';
            desc = "Reveal";
            for = "linux";
          }
          {
            run = ''open -R "''$1"'';
            desc = "Reveal";
            for = "macos";
          }
          {
            run = ''explorer /select,"%1"'';
            desc = "Reveal";
            orphan = true;
            for = "windows";
          }
          {
            run = ''clear; exiftool "''$1"; echo "Press enter to exit"; read _'';
            desc = "Show EXIF";
            block = true;
            for = "unix";
          }
        ];

        # Extract archives
        extract = [
          {
            run = ''ouch d -y "$@"'';
            desc = "Extract here with ouch";
            for = "unix";
          }
        ];

        # Download files if browsing a remove location, so not on the local disk
        download = [
          {
            run = ''ya emit download --open "$@"'';
            desc = "Download and open";
          }
          {
            run = ''ya emit download "$@"'';
            desc = "Download";
          }
        ];
      };

      # Tells Yazi how to handle different file types
      # They match the name or mime type of the file
      open = {
        rules = [
          {
            name = "*/"; # Directories
            use = [
              "open"
              "reveal"
            ];
          }
          {
            mime = "text/*"; # Text files
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "image/*"; # Image files
            use = [
              "open"
              "reveal"
            ];
          }
          {
            mime = "{audio,video}/*"; # Media files
            use = [
              "play"
              "reveal"
            ];
          }
          {
            mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}"; # Archive files
            use = [
              "extract"
              "reveal"
            ];
          }
          {
            mime = "application/{json,ndjson}"; # JSON files
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "*/javascript"; # JavaScript files
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "inode/empty"; # Empty files
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "vfs/{absent,stale}"; # Remote files that are not yet downloaded
            use = "download";
          }
          {
            name = "*.html"; # HTML files
            use = [
              "edit"
              "reveal"
            ];
          }

          {
            name = "*"; # Fallback for all other files
            use = [
              "open"
              "reveal"
            ];
          }
        ];
      };

      # Performance and background tasks
      tasks = {
        micro_workers = 30; # The number of threads for small, quick tasks (e.g., reading metadata, simple logic).
        macro_workers = 24; # The number of threads for heavy, slow tasks (e.g., recursive searching, bulk copying/moving files).
        bizarre_retry = 5; # How many times Yazi retries a task that failed for an unexpected ("bizarre") reason before giving up
        image_alloc = 1073741824; # maximum memory (in bytes) Yazi is allowed to use for decoding images.

        # maximum pixel dimensions (Width x Height) Yazi will attempt to decode.
        image_bound = [
          20000
          20000
        ];
        suppress_preload = false; # "Preloading" reads the next file in the list before you even select it, making navigation feel instant.
      };

      # Plugin-specific settings
      plugin = {
        # small plugins that run in the background to gather info about files
        fetchers = [
          {
            id = "mime";
            name = "*/";
            run = "mime";
            "if" = "!mime";
            prio = "high";
          }
          {
            id = "mime";
            name = "*";
            run = "mime";
            "if" = "!mime";
            prio = "high";
          }
        ];
      };
    };
  };

  xdg.desktopEntries.yazi = lib.mkForce {
    name = "Yazi";
    genericName = "File Manager";
    exec = "${vars.term} --class yazi -e yazi";
    terminal = false;
    categories = [
      "System"
      "FileTools"
      "FileManager"
    ];
    mimeType = [ "inode/directory" ];
  };

  home.packages = with pkgs; [
    fzf
    zoxide
    ripgrep
    fd
    ffmpeg
    poppler
    jq
    zip
    unzip
    p7zip
    gnutar
    ueberzugpp
    chafa
    xdg-utils
    exiftool
    ouch
  ];
}
