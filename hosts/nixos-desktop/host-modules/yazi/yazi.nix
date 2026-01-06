{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

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
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;
        sort_translit = false;
        linemode = "none";
        show_hidden = false;
        show_symlink = true;
        scrolloff = 5;
        mouse_events = [
          "click"
          "scroll"
        ];
        title_format = "Yazi: {cwd}";
      };

      preview = {
        wrap = "no";
        tab_size = 2;
        max_width = 600;
        max_height = 900;
        cache_dir = "";
        image_delay = 30;
        image_filter = "triangle";
        image_quality = 75;
        ueberzug_scale = 1;
        ueberzug_offset = [
          0
          0
          0
          0
        ];
      };

      opener = {
        edit = [
          {
            run = ''''${EDITOR:-vi} "$@"'';
            desc = "$EDITOR";
            block = true;
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
        extract = [
          {
            run = ''ya pub extract --list "$@"'';
            desc = "Extract here";
          }
        ];
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

      open = {
        rules = [
          {
            name = "*/";
            use = [
              "edit"
              "open"
              "reveal"
            ];
          }
          {
            mime = "text/*";
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "image/*";
            use = [
              "open"
              "reveal"
            ];
          }
          {
            mime = "{audio,video}/*";
            use = [
              "play"
              "reveal"
            ];
          }
          {
            mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
            use = [
              "extract"
              "reveal"
            ];
          }
          {
            mime = "application/{json,ndjson}";
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "*/javascript";
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "inode/empty";
            use = [
              "edit"
              "reveal"
            ];
          }
          {
            mime = "vfs/{absent,stale}";
            use = "download";
          }
          {
            name = "*";
            use = [
              "open"
              "reveal"
            ];
          }
        ];
      };

      tasks = {
        micro_workers = 10;
        macro_workers = 10;
        bizarre_retry = 3;
        image_alloc = 536870912;
        image_bound = [
          10000
          10000
        ];
        suppress_preload = false;
      };

      plugin = {
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

  home.packages = with pkgs; [
    fzf
    zoxide
    ripgrep
    fd
    ffmpeg
    poppler
    jq
    p7zip
    ueberzugpp
    chafa
  ];
}
