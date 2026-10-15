# Set defaults applications. If not enabled the system does not know with what to open file/directories/links and similar
{ delib
, lib
, pkgs
, config
, moduleSystem
, options
, ...
}:
let
  mediaRoles = {
    videoPlayer = {
      default = "mpv";
      types = [
        "video/mp4"
        "video/x-m4v"
        "video/quicktime"
        "video/x-matroska"
        "video/webm"
        "video/vnd.avi"
        "video/x-msvideo"
        "video/mp2t"
        "video/mpeg"
        "video/3gpp"
        "video/ogg"
        "video/x-flv"
        "application/mxf"
      ];
    };
    audioPlayer = {
      default = "mpv";
      types = [
        "audio/mpeg"
        "audio/mp3"
        "audio/x-mp3"
        "audio/mp4"
        "audio/x-m4a"
        "audio/aac"
        "audio/flac"
        "audio/x-flac"
        "audio/ogg"
        "audio/vorbis"
        "audio/x-vorbis+ogg"
        "audio/opus"
        "audio/x-opus+ogg"
        "audio/wav"
        "audio/x-wav"
        "audio/webm"
        "audio/x-matroska"
        "audio/x-ms-wma"
        "audio/aiff"
        "audio/x-aiff"
        "audio/x-ape"
        "audio/x-wavpack"
        "audio/x-mpegurl"
        "audio/x-scpls"
        "application/ogg"
      ];
    };
    imageViewer = {
      default = "gwenview";
      types = [
        "image/jpeg"
        "image/png"
        "image/gif"
        "image/webp"
        "image/avif"
        "image/bmp"
        "image/tiff"
        "image/x-icon"
        "image/vnd.microsoft.icon"
        "image/svg+xml"
        "image/heif"
        "image/heic"
        "image/jxl"
        "image/vnd.adobe.photoshop"
        "image/x-xcf"
        "image/x-dcraw"
        "image/x-adobe-dng"
        "image/x-canon-cr2"
        "image/x-canon-cr3"
        "image/x-nikon-nef"
        "image/x-sony-arw"
        "image/x-fuji-raf"
        "image/x-olympus-orf"
        "image/x-panasonic-rw2"
        "image/x-pentax-pef"
      ];
    };
    pdfViewer = {
      default = "zathura";
      types = [ "application/pdf" ];
    };
    docEditor = {
      default = "libreoffice";
      types = [
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
        "application/vnd.oasis.opendocument.text"
        "application/vnd.oasis.opendocument.text-template"
        "application/msword"
        "application/rtf"
        "text/rtf"
      ];
    };
    sheetEditor = {
      default = "libreoffice";
      types = [
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
        "application/vnd.oasis.opendocument.spreadsheet"
        "application/vnd.oasis.opendocument.spreadsheet-template"
        "application/vnd.ms-excel"
        "text/csv"
      ];
    };
    slideEditor = {
      default = "libreoffice";
      types = [
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
        "application/vnd.oasis.opendocument.presentation"
        "application/vnd.oasis.opendocument.presentation-template"
        "application/vnd.ms-powerpoint"
      ];
    };
    archiveManager = {
      default = "ark";
      types = [
        "application/zip"
        "application/x-tar"
        "application/gzip"
        "application/x-compressed-tar"
        "application/x-bzip2"
        "application/x-bzip2-compressed-tar"
        "application/x-xz"
        "application/x-xz-compressed-tar"
        "application/zstd"
        "application/x-zstd-compressed-tar"
        "application/x-lzma"
        "application/x-7z-compressed"
        "application/vnd.rar"
        "application/x-rar"
      ];
    };
  };

  desktopIds = {
    mpv = "mpv.desktop";
    vlc = "vlc.desktop";
    celluloid = "io.github.celluloid_player.Celluloid.desktop";
    haruna = "org.kde.haruna.desktop";
    gwenview = "org.kde.gwenview.desktop";
    okular = "org.kde.okular.desktop";
    zathura = "org.pwmt.zathura.desktop";
    ark = "org.kde.ark.desktop";
    file-roller = "org.gnome.FileRoller.desktop";
    kate = "org.kde.kate.desktop";
  };

  officeDesktopIds = {
    docEditor = "writer.desktop";
    sheetEditor = "calc.desktop";
    slideEditor = "impress.desktop";
  };

  kdeFirst = [ "ark" "gwenview" "okular" "haruna" ];

  isFlatpakId = name: builtins.match "[A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+){2,}" name != null;

  isDesktopId = lib.hasSuffix ".desktop";

  desktopIdOf =
    role: name:
    if isDesktopId name then
      name
    else if isFlatpakId name then
      "${name}.desktop"
    else if lib.hasPrefix "libreoffice" name && officeDesktopIds ? ${role} then
      officeDesktopIds.${role}
    else
      desktopIds.${name} or "${name}.desktop";

  getPkg =
    name:
    if builtins.elem name kdeFirst && pkgs.kdePackages ? ${name} then
      pkgs.kdePackages.${name}
    else
      pkgs.${name} or pkgs.kdePackages.${name} or null;

  providedBy =
    myconfig:
    let
      user = myconfig.constants.user;

      # nixpkgs-removed options (mkRemovedOptionModule) throw when read; treat them as not enabled
      readEnable =
        path:
        let
          r = builtins.tryEval (lib.attrByPath path false config);
        in
        r.success && r.value == true;
    in
    rec {
      isProgramEnabled =
        name:
        readEnable [ "programs" name "enable" ]
        || readEnable [ "home-manager" "users" user "programs" name "enable" ];

      userPackageNames = map lib.getName (
        lib.attrByPath [ "home-manager" "users" user "home" "packages" ] [ ] config
      );

      flatpakIds = map (p: if builtins.isAttrs p then p.appId else p) (
        lib.attrByPath [ "services" "flatpak" "packages" ] [ ] config
        ++ lib.attrByPath [ "home-manager" "users" user "services" "flatpak" "packages" ] [ ] config
      );

      isProvided = name: isProgramEnabled name || builtins.elem name userPackageNames;
    };

  resolveExtras =
    myconfig:
    let
      p = providedBy myconfig;
      entries = map
        (name: {
          inherit name;
          pkg = getPkg name;
          ok = getPkg name != null || p.isProvided name;
        })
        (lib.unique myconfig.constants.extraAppPackages);
    in
    {
      install = lib.concatMap
        (e: lib.optional (e.pkg != null && !p.isProvided e.name) e.pkg)
        entries;
      okNames = map (e: e.name) (lib.filter (e: e.ok) entries);
      unresolved = map (e: e.name) (lib.filter (e: !e.ok) entries);
    };

  resolveMedia =
    myconfig:
    let
      p = providedBy myconfig;
      extras = resolveExtras myconfig;

      desktopIdProvidedByExtra =
        id:
        let
          stem = lib.removeSuffix ".desktop" id;
          lastSegment = lib.toLower (lib.last (lib.splitString "." stem));
        in
        lib.any
          (n:
          desktopIds.${n} or "${n}.desktop" == id
          || lastSegment == lib.replaceStrings [ "-" "_" ] [ "" "" ] (lib.toLower n))
          extras.okNames;

      isPresent =
        name:
        if isDesktopId name then
          let
            stem = lib.removeSuffix ".desktop" name;
          in
          (isFlatpakId stem && builtins.elem stem p.flatpakIds) || desktopIdProvidedByExtra name
        else if isFlatpakId name then
          builtins.elem name p.flatpakIds
        else
          getPkg name != null || p.isProgramEnabled name || builtins.elem name p.userPackageNames;
    in
    lib.mapAttrs
      (
        role: spec:
        let
          want = myconfig.constants.${role};
          usable = want == spec.default || isPresent want;
          name = if usable then want else spec.default;
          external = isFlatpakId name || isDesktopId name;
        in
        {
          inherit role want name;
          inherit (spec) types;
          fellBack = !usable;
          flatpak = isFlatpakId name;
          desktop = desktopIdOf role name;
          install = lib.optional
            (!external && getPkg name != null && !p.isProgramEnabled name && !builtins.elem name p.userPackageNames)
            (getPkg name);
        }
      )
      mediaRoles;
in
delib.module {
  name = "mime";
  options = delib.singleEnableOption true;

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      media = lib.attrValues (resolveMedia myconfig);
      extras = resolveExtras myconfig;
    in
    {
      home-manager.users.${myconfig.constants.user}.xdg.configFile."mimeapps.list".force = true;

      environment.systemPackages = lib.unique (lib.concatMap (e: e.install) media ++ extras.install);

      warnings =
        lib.concatMap
          (e:
            lib.optional e.fellBack
              "mime: constants ${e.role} = \"${e.want}\" is ${
                if isDesktopId e.want then "neither provided by constants extraAppPackages nor a flatpak id in services.flatpak.packages"
                else if isFlatpakId e.want then "not in services.flatpak.packages"
                else "neither a package in pkgs/pkgs.kdePackages nor provided by an enabled module"
              }; using the default \"${e.name}\" instead.")
          media
        ++ lib.optional (extras.unresolved != [ ])
          "mime: constants extraAppPackages has names that are neither a package in pkgs/pkgs.kdePackages nor provided by an enabled module (${lib.concatStringsSep ", " extras.unresolved}); nothing is installed for them.";
    };

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      mediaDefaults = lib.mergeAttrsList (
        map (e: lib.genAttrs e.types (_: e.desktop)) (lib.attrValues (resolveMedia myconfig))
      );

      editor = myconfig.constants.editor;
      browser = myconfig.constants.browser;
      termName = myconfig.constants.terminal.name;
      fileManager = myconfig.constants.fileManager;

      nvimEntry = {
        bin = "nvim";
        icon = "nvim";
        name = "Neovim (User)";
      };

      hasKritNvim =
        moduleSystem == "nixos"
        && (options ? myconfig.krit.programs.neovim)
        && (myconfig.krit.programs.neovim.enable or false);

      termEditors = {
        neovim = nvimEntry;
        nvim = nvimEntry;
        vim = {
          bin = "vim";
          icon = "vim";
          name = "Vim (User)";
        };
        nano = {
          bin = "nano";
          icon = "nano";
          name = "Nano (User)";
        };
        helix = {
          bin = "hx";
          icon = "helix";
          name = "Helix (User)";
        };
      };

      isNvimEditor = editor == "neovim" || editor == "nvim";
      deferToKritNvim = hasKritNvim && isNvimEditor;
      isTermEditor = builtins.hasAttr editor termEditors && !deferToKritNvim;
      editorConfig = termEditors.${editor};

      browserDesktopMap = {
        "brave" = "brave-browser.desktop";
        "chrome" = "google-chrome.desktop";
        "chromium" = "chromium-browser.desktop";
      };

      myEditor =
        if deferToKritNvim then
          "custom-nvim.desktop"
        else if isTermEditor then
          "user-${editor}.desktop"
        else if editor == "vscode" || editor == "code" then
          "code.desktop"
        else
          "${editor}.desktop";

      myBrowser = browserDesktopMap.${browser} or "${browser}.desktop";

      myMailer =
        if (myconfig.programs.thunderbird.enable or false) then
          "thunderbird.desktop"
        else
          myBrowser;

      myFileManager =
        if fileManager == "dolphin" then "org.kde.dolphin.desktop" else "${fileManager}.desktop";

    in
    {
      # -----------------------------------------------------------------------
      # 🖥️ CUSTOM DESKTOP ENTRY (Terminal Editors Only)
      # -----------------------------------------------------------------------
      xdg.desktopEntries = lib.mkIf isTermEditor {
        "user-${editor}" = {
          inherit (editorConfig) name icon;
          genericName = "Text Editor";
          comment = "Edit text files in ${termName}";
          exec = "${termName} -e ${editorConfig.bin} %F";
          terminal = false;
          categories = [
            "Utility"
            "TextEditor"
          ];
          mimeType = [
            "text/plain"
            "text/markdown"
            "text/x-nix"
          ];
        };
      };

      # -----------------------------------------------------------------------
      # 📂 MIME ASSOCIATIONS
      # -----------------------------------------------------------------------
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          # Directories
          "inode/directory" = myFileManager;

          # Browser
          "text/html" = myBrowser;
          "x-scheme-handler/http" = myBrowser;
          "x-scheme-handler/https" = myBrowser;
          "x-scheme-handler/about" = myBrowser;
          "x-scheme-handler/unknown" = myBrowser;

          # Mail (Thunderbird when enabled, otherwise the browser)
          "x-scheme-handler/mailto" = myMailer;

          # Editor
          "text/plain" = myEditor;
          "text/markdown" = myEditor;
          "application/x-shellscript" = myEditor;
          "application/json" = myEditor;
          "text/x-nix" = myEditor;
        } // mediaDefaults;
      };
    };
}
