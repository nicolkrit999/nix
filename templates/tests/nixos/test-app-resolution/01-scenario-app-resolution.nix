let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;
  lib = flake.inputs.nixpkgs.lib;
  shared = src + "/templates/tests/nixos/test-app-resolution/shared";

  mkTree = withKrit:
    (denix.lib.configurations {
      moduleSystem = "nixos";
      homeManagerUser = "krit";
      extensions = with denix.lib.extensions; [
        args
        (base.withConfig {
          args.enable = true;
          rices.enable = false;
        })
      ];
      specialArgs = { inherit (flake) inputs; moduleSystem = "nixos"; };
      paths = [
        (shared + "/host-app-resolution.nix")
        (shared + "/extra.nix")
        (shared + "/stylix-stub.nix")
        (shared + "/thunderbird-stub.nix")
        (src + "/modules/nixos/toplevel/home-manager.nix")
        (src + "/modules/nixos/config/constants-nixos.nix")
        (src + "/modules/common/config/constants.nix")
        (src + "/modules/nixos/toplevel/home-packages-nixos.nix")
        (src + "/modules/nixos/toplevel/mime.nix")
        (src + "/modules/common/programs/zen-browser.nix")
      ] ++ lib.optionals withKrit [
        (src + "/modules/common/programs/neovim.nix")
        (src + "/users/krit/common/programs/cli-programs/neovim.nix")
        (src + "/users/krit/nixos/programs/file-managers/dolphin.nix")
      ];
      exclude = [ ];
    }).app-resolution;

  bareSys = mkTree false;
  kritSys = mkTree true;
  twin = sys: modules: (sys.extendModules { inherit modules; }).config;
  mk = lib.mkForce;
  constants = c: { myconfig.constants = lib.mapAttrs (_: mk) c; };
  mimeOpts = c: { myconfig.mime = lib.mapAttrs (_: mk) c; };

  hm = c: c.home-manager.users.krit;
  names = c: map lib.getName (c.environment.systemPackages ++ (hm c).home.packages);
  installs = c: n: builtins.length (builtins.filter (x: x == n) (names c));
  entries = c: builtins.attrNames (hm c).xdg.desktopEntries;
  mimeOf = c: k: lib.toList (hm c).xdg.mimeApps.defaultApplications.${k};
  textTypes = [ "text/plain" "text/markdown" "application/x-shellscript" "application/json" "text/x-nix" ];
  browserTypes = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" "x-scheme-handler/about" "x-scheme-handler/unknown" ];
  videoTypes = [ "video/mp4" "video/x-m4v" "video/quicktime" "video/x-matroska" "video/webm" "video/vnd.avi" "video/x-msvideo" "video/mp2t" "video/mpeg" "video/3gpp" "video/ogg" "video/x-flv" "application/mxf" ];
  audioTypes = [ "audio/mpeg" "audio/mp3" "audio/mp4" "audio/x-m4a" "audio/aac" "audio/flac" "audio/ogg" "audio/vorbis" "audio/opus" "audio/x-wav" "audio/webm" "audio/x-ms-wma" "audio/x-aiff" "audio/x-ape" "audio/x-mpegurl" "audio/x-scpls" "application/ogg" ];
  imageTypes = [ "image/jpeg" "image/png" "image/gif" "image/webp" ];
  imageExtraTypes = [ "image/avif" "image/bmp" "image/tiff" "image/x-icon" "image/svg+xml" "image/heic" "image/jxl" "image/vnd.adobe.photoshop" "image/x-xcf" "image/x-adobe-dng" "image/x-canon-cr2" "image/x-nikon-nef" "image/x-sony-arw" ];
  pdfTypes = [ "application/pdf" ];
  docTypes = [ "application/vnd.openxmlformats-officedocument.wordprocessingml.document" "application/vnd.oasis.opendocument.text" "application/msword" "application/rtf" "text/rtf" ];
  sheetTypes = [ "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" "application/vnd.oasis.opendocument.spreadsheet" "application/vnd.ms-excel" "text/csv" ];
  slideTypes = [ "application/vnd.openxmlformats-officedocument.presentationml.presentation" "application/vnd.oasis.opendocument.presentation" "application/vnd.ms-powerpoint" ];
  archiveTypes = [ "application/zip" "application/x-tar" "application/gzip" "application/x-xz" "application/x-bzip2" "application/zstd" "application/x-compressed-tar" "application/x-7z-compressed" "application/vnd.rar" ];
  warnsOf = c: builtins.filter (w: lib.hasPrefix "home-packages: constants " w || lib.hasPrefix "mime: " w) c.warnings;

  ok = "ok";
  failIf = problems: if problems == [ ] then ok else "FAIL: ${builtins.concatStringsSep "; " problems}";
  detects = what: problems: if problems != [ ] then ok else "FAIL: control did not detect: ${what}";
  eq = what: got: want: if got == want then ok else "FAIL: ${what}: got ${builtins.toJSON got}, expected ${builtins.toJSON want}";
  all = xs: failIf (builtins.filter (x: x != ok) xs);

  onceProblems = c: n:
    lib.optional (installs c n != 1) "${n} installed ${toString (installs c n)} times, expected exactly 1";
  mimeProblems = c: types: want:
    lib.concatMap (t: lib.optional (mimeOf c t != [ want ]) "${t} -> ${builtins.toJSON (mimeOf c t)}, expected ${want}") types;
  entryProblems = c: present: absent:
    (map (e: "desktop entry ${e} missing") (builtins.filter (e: !(builtins.elem e (entries c))) present))
    ++ (map (e: "desktop entry ${e} must not exist") (builtins.filter (e: builtins.elem e (entries c)) absent));
  quietProblems = c: map (w: "unexpected warning: ${w}") (warnsOf c);
  loneWarnProblems = c: role: name:
    let
      ws = warnsOf c;
      mine = builtins.filter (w: lib.hasInfix "mime: ${role} = \"${name}\"" w || lib.hasInfix "constants ${role} = \"${name}\"" w) ws;
    in
    lib.optional (builtins.length mine != 1) "expected exactly 1 warning for ${role} = ${name}, got ${toString (builtins.length mine)}"
    ++ lib.optional (builtins.length ws != builtins.length mine) "unrelated warnings: ${builtins.toJSON ws}";

  vanilla = twin bareSys [ ];
  pk = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  dupInstall = sys: mods: pkg: twin sys (mods ++ [{ environment.systemPackages = [ pkg ]; }]);

  nvimBare = twin bareSys [ (constants { editor = "neovim"; }) ];
  nvimOffInKritTree = twin kritSys [ (constants { editor = "neovim"; }) ];
  nvimKritMods = [ (constants { editor = "neovim"; }) { myconfig.krit.programs.neovim.enable = true; } ];
  nvimKrit = twin kritSys nvimKritMods;
  nvimAliasKrit = twin kritSys [ (constants { editor = "nvim"; }) { myconfig.krit.programs.neovim.enable = true; } ];
  vimWithKritNvim = twin kritSys [{ myconfig.krit.programs.neovim.enable = true; }];

  dolphinKritMods = [ (constants { fileManager = "dolphin"; }) { myconfig.krit.programs.dolphin.enable = true; } ];
  dolphinKrit = twin kritSys dolphinKritMods;
  dolphinBare = twin bareSys [ (constants { fileManager = "dolphin"; }) ];

  ffNixosMods = [ (constants { browser = "firefox"; }) { programs.firefox.enable = true; } ];
  ffNixos = twin bareSys ffNixosMods;
  ffHome = twin bareSys [ (constants { browser = "firefox"; }) { home-manager.users.krit.programs.firefox.enable = true; } ];
  ffVanilla = twin bareSys [ (constants { browser = "firefox"; }) ];
  zenModule = twin bareSys [ (constants { browser = "zen-beta"; }) { myconfig.programs.zen.browser.enable = true; } ];
  zenInPkgsMod = { nixpkgs.overlays = [ (_: prev: { zen-beta = prev.writeShellScriptBin "zen-beta" "true"; }) ]; };
  zenModuleInPkgs = twin bareSys [ (constants { browser = "zen-beta"; }) { myconfig.programs.zen.browser.enable = true; } zenInPkgsMod ];
  zenInPkgsOnly = twin bareSys [ (constants { browser = "zen-beta"; }) zenInPkgsMod ];
  zenNoModule = twin bareSys [ (constants { browser = "zen-beta"; }) ];
  schoolWrapper = twin bareSys [
    (constants { browser = "brave-school"; })
    { home-manager.users.krit.home.packages = [ (flake.inputs.nixpkgs.legacyPackages.x86_64-linux.writeShellScriptBin "brave-school" "true") ]; }
  ];
  unknownBrowser = twin bareSys [ (constants { browser = "no-such-browser-xyz"; }) ];
  unknownTwo = twin bareSys [ (constants { browser = "no-such-browser-xyz"; fileManager = "no-such-fm-xyz"; }) ];
  flatpakCraft = [{ services.flatpak.packages = [{ appId = "ai.storyteller.wordcraft"; } "ai.storyteller.gridcraft"]; }];
  docCraft = [ (mimeOpts { docEditor = "ai.storyteller.wordcraft"; sheetEditor = "ai.storyteller.gridcraft"; }) ];
  craftPresent = twin bareSys (docCraft ++ flatpakCraft);
  craftMissing = twin bareSys docCraft;
  vlcVideo = twin bareSys [ (mimeOpts { videoPlayer = "vlc"; audioPlayer = "vlc"; }) ];
  unknownVideo = twin bareSys [ (mimeOpts { videoPlayer = "no-such-player-xyz"; }) ];
  officeCraftMods = [
    (mimeOpts { docEditor = "ai.storyteller.wordcraft"; sheetEditor = "ai.storyteller.gridcraft"; slideEditor = "ai.storyteller.deckcraft"; })
    { services.flatpak.packages = [{ appId = "ai.storyteller.wordcraft"; } "ai.storyteller.gridcraft" "ai.storyteller.deckcraft"]; }
  ];
  officeCraft = twin bareSys officeCraftMods;
  imageCraftWant = mimeOpts { imageViewer = "ai.storyteller.photocraft"; };
  imageCraft = twin bareSys [ imageCraftWant { services.flatpak.packages = [ "ai.storyteller.photocraft" ]; } ];
  imageCraftMissing = twin bareSys [ imageCraftWant ];
  pdfOkular = twin bareSys [ (mimeOpts { pdfViewer = "okular"; }) ];
  archiveFileRoller = twin bareSys [ (mimeOpts { archiveManager = "file-roller"; }) ];
  archiveXarchiver = twin bareSys [ (mimeOpts { archiveManager = "xarchiver"; }) ];
  unknownArchive = twin bareSys [ (mimeOpts { archiveManager = "no-such-archiver-xyz"; }) ];
  zathuraHmMod = { home-manager.users.krit.programs.zathura.enable = true; };
  zathuraHm = twin bareSys [ zathuraHmMod ];
  playerWrapper = twin bareSys [
    (mimeOpts { videoPlayer = "my-player"; })
    { home-manager.users.krit.home.packages = [ (pk.writeShellScriptBin "my-player" "true") ]; }
  ];
  mpvExplicit = twin bareSys [ (mimeOpts { videoPlayer = "mpv"; audioPlayer = "mpv"; }) ];
  roleNames = [ "videoPlayer" "audioPlayer" "imageViewer" "pdfViewer" "docEditor" "sheetEditor" "slideEditor" "archiveManager" ];
  allUnknown = twin bareSys [ (mimeOpts (lib.genAttrs roleNames (r: "no-such-${r}-xyz"))) ];
  unknownEditor = twin bareSys [ (constants { editor = "no-such-editor-xyz"; }) ];

  mailThunderbird = twin bareSys [{ myconfig.programs.thunderbird.enable = true; }];
  braveBrowser = twin bareSys [ (constants { browser = "brave"; }) ];
  chromeBrowser = twin bareSys [ (constants { browser = "chrome"; }) ];
  fooTerm = twin bareSys [{ myconfig.constants.terminal.name = mk "foot"; }];
  helixEd = twin bareSys [ (constants { editor = "helix"; }) ];
  codeEd = twin bareSys [ (constants { editor = "code"; }) ];
  mimeOff = twin bareSys [{ myconfig.mime.enable = mk false; }];
  homePkgsOff = twin bareSys [{ myconfig.home-packages.enable = mk false; }];

  extraWarnsOf = c: builtins.filter (lib.hasPrefix "mime: extraAppPackages") c.warnings;
  extraTwin = list: twin bareSys [ (mimeOpts { extraAppPackages = list; }) ];
  extraHello = extraTwin [ "hello" ];
  extraKate = extraTwin [ "kate" ];
  extraUnknown = extraTwin [ "no-such-extra-xyz" ];
  extraMixed = extraTwin [ "hello" "no-such-extra-a" "no-such-extra-b" "hello" ];
  extraMpv = extraTwin [ "mpv" ];
  extraZathuraHm = twin bareSys [ zathuraHmMod (mimeOpts { extraAppPackages = [ "zathura" ]; }) ];
  extraWrapper = twin bareSys [
    (mimeOpts { extraAppPackages = [ "my-extra-wrapper" ]; })
    { home-manager.users.krit.home.packages = [ (pk.writeShellScriptBin "my-extra-wrapper" "true") ]; }
  ];
  kateDesktop = "org.kde.kate.desktop";
  kateRole = twin bareSys [ (mimeOpts { docEditor = kateDesktop; extraAppPackages = [ "kate" ]; }) ];
  kateRoleNoExtra = twin bareSys [ (mimeOpts { docEditor = kateDesktop; }) ];
  kateRoleWrongExtra = twin bareSys [ (mimeOpts { docEditor = kateDesktop; extraAppPackages = [ "hello" ]; }) ];
  craftDesktopMods = [ (mimeOpts { docEditor = "ai.storyteller.wordcraft.desktop"; }) ];
  craftDesktopPresent = twin bareSys (craftDesktopMods ++ flatpakCraft);
  craftDesktopMissing = twin bareSys craftDesktopMods;
  rollerDesktop = twin bareSys [ (mimeOpts { archiveManager = "org.gnome.FileRoller.desktop"; extraAppPackages = [ "file-roller" ]; }) ];
  safeEval = v: (builtins.tryEval (builtins.deepSeq v true)).success;
  mpvName = lib.getName pk.mpv;
  zathuraName = lib.getName pk.zathura;
  allOnce = c: ns: lib.concatMap (onceProblems c) ns;
  execOf = c: e: (hm c).xdg.desktopEntries.${e}.exec;
  forceOf = c: (hm c).xdg.configFile."mimeapps.list".force or false;

  groups = {
    vanilla = {
      "vanilla: browser, editor, file manager, terminal each installed exactly once" =
        failIf (allOnce vanilla [ "chromium" "vim" "yazi" "kitty" ]);
      "vanilla: cliphist and gwenview installed exactly once" =
        failIf (allOnce vanilla [ "cliphist" "gwenview" ]);
      "vanilla: no home-packages warning" = failIf (quietProblems vanilla);
      "vanilla: one launcher (user-vim), text MIME -> user-vim.desktop" =
        failIf (entryProblems vanilla [ "user-vim" ] [ "custom-nvim" "user-neovim" ] ++ mimeProblems vanilla textTypes "user-vim.desktop");
      "vanilla: browser MIME -> chromium-browser.desktop, mailto follows the browser" =
        failIf (mimeProblems vanilla (browserTypes ++ [ "x-scheme-handler/mailto" ]) "chromium-browser.desktop");
      "vanilla: inode/directory -> yazi.desktop, images -> gwenview" =
        failIf (mimeProblems vanilla [ "inode/directory" ] "yazi.desktop"
          ++ mimeProblems vanilla imageTypes "org.kde.gwenview.desktop");
      "control(once): a second install is detected" =
        detects "two chromium" (onceProblems (dupInstall bareSys [ ] pk.chromium) "chromium");
      "control(once): home-packages disabled installs nothing" =
        detects "no chromium" (onceProblems homePkgsOff "chromium");
    };
    editor = {
      "editor vim: user-vim exec uses terminal.name" =
        eq "exec" (execOf vanilla "user-vim") "kitty -e vim %F";
      "editor vim: terminal foot changes the exec (control: not hardcoded)" =
        all [ (eq "exec" (execOf fooTerm "user-vim") "foot -e vim %F") (eq "kitty exec differs" (execOf fooTerm "user-vim" != execOf vanilla "user-vim") true) ];
      "editor helix: user-helix entry runs hx in the terminal" =
        all [ (failIf (entryProblems helixEd [ "user-helix" ] [ "user-vim" ] ++ mimeProblems helixEd textTypes "user-helix.desktop")) (eq "exec" (execOf helixEd "user-helix") "kitty -e hx %F") ];
      "editor code: code.desktop, no user entry" =
        failIf (entryProblems codeEd [ ] [ "user-code" ] ++ mimeProblems codeEd textTypes "code.desktop");
    };
    neovim = {
      "editor neovim without the krit tree: pkgs neovim once, user-neovim launcher" =
        failIf (onceProblems nvimBare "neovim" ++ entryProblems nvimBare [ "user-neovim" ] [ "custom-nvim" ]
          ++ mimeProblems nvimBare textTypes "user-neovim.desktop" ++ quietProblems nvimBare);
      "editor neovim, krit neovim module loaded but off: same as without it" =
        failIf (onceProblems nvimOffInKritTree "neovim" ++ entryProblems nvimOffInKritTree [ "user-neovim" ] [ "custom-nvim" ]
          ++ mimeProblems nvimOffInKritTree textTypes "user-neovim.desktop");
      "editor neovim, krit neovim module on: one package, one launcher (custom-nvim), no warning" =
        failIf (onceProblems nvimKrit "neovim" ++ entryProblems nvimKrit [ "custom-nvim" ] [ "user-neovim" ]
          ++ mimeProblems nvimKrit textTypes "custom-nvim.desktop" ++ quietProblems nvimKrit);
      "editor nvim alias, krit neovim module on: one package, custom-nvim launcher" =
        failIf (onceProblems nvimAliasKrit "neovim" ++ entryProblems nvimAliasKrit [ "custom-nvim" ] [ "user-neovim" "user-nvim" ]
          ++ mimeProblems nvimAliasKrit textTypes "custom-nvim.desktop");
      "editor vim, krit neovim module on: vim keeps its own launcher and MIME default" =
        failIf (onceProblems vimWithKritNvim "vim" ++ entryProblems vimWithKritNvim [ "user-vim" "custom-nvim" ] [ ]
          ++ mimeProblems vimWithKritNvim textTypes "user-vim.desktop");
      "control(editor): a second neovim install is detected" =
        detects "two neovim" (onceProblems (dupInstall kritSys nvimKritMods pk.neovim) "neovim");
      "control(editor): module-off twin does not satisfy the module-on MIME expectation" =
        detects "custom-nvim on module-off" (mimeProblems nvimOffInKritTree textTypes "custom-nvim.desktop");
      "control(editor): module-on twin does not satisfy the user-neovim expectation" =
        detects "user-neovim on module-on" (entryProblems nvimKrit [ "user-neovim" ] [ ]);
    };
    dolphin = {
      "fileManager dolphin with the krit dolphin module: one dolphin, org.kde.dolphin.desktop, no warning" =
        failIf (onceProblems dolphinKrit "dolphin" ++ mimeProblems dolphinKrit [ "inode/directory" ] "org.kde.dolphin.desktop" ++ quietProblems dolphinKrit);
      "fileManager dolphin without the krit tree: one dolphin, org.kde.dolphin.desktop" =
        failIf (onceProblems dolphinBare "dolphin" ++ mimeProblems dolphinBare [ "inode/directory" ] "org.kde.dolphin.desktop" ++ quietProblems dolphinBare);
      "control(fileManager): a second dolphin install is detected" =
        detects "two dolphin" (onceProblems (dupInstall kritSys dolphinKritMods pk.kdePackages.dolphin) "dolphin");
    };
    browser = {
      "browser firefox via programs.firefox.enable (system): one firefox, firefox.desktop, no warning" =
        failIf (onceProblems ffNixos "firefox" ++ mimeProblems ffNixos browserTypes "firefox.desktop" ++ quietProblems ffNixos);
      "browser firefox via programs.firefox.enable (home-manager): one firefox, no warning" =
        failIf (onceProblems ffHome "firefox" ++ mimeProblems ffHome browserTypes "firefox.desktop" ++ quietProblems ffHome);
      "browser firefox with no module: installed once from pkgs" =
        failIf (onceProblems ffVanilla "firefox" ++ quietProblems ffVanilla);
      "browser zen-beta via the zen module: one zen-beta, zen-beta.desktop, no warning" =
        failIf (onceProblems zenModule "zen-beta" ++ mimeProblems zenModule browserTypes "zen-beta.desktop" ++ quietProblems zenModule);
      "browser zen-beta also in pkgs, zen module on: still one zen-beta (the alias defers to the module)" =
        failIf (onceProblems zenModuleInPkgs "zen-beta" ++ quietProblems zenModuleInPkgs);
      "control(browser): zen-beta in pkgs without the module is installed once from pkgs" =
        failIf (onceProblems zenInPkgsOnly "zen-beta" ++ quietProblems zenInPkgsOnly);
      "browser brave / chrome: browserDesktopMap names" =
        failIf (mimeProblems braveBrowser browserTypes "brave-browser.desktop" ++ mimeProblems chromeBrowser browserTypes "google-chrome.desktop");
      "mailto follows thunderbird when enabled, the browser otherwise" =
        failIf (mimeProblems mailThunderbird [ "x-scheme-handler/mailto" ] "thunderbird.desktop"
          ++ mimeProblems mailThunderbird browserTypes "chromium-browser.desktop"
          ++ mimeProblems vanilla [ "x-scheme-handler/mailto" ] "chromium-browser.desktop");
      "control(browser): a second firefox install (system module on) is detected" =
        detects "two firefox" (onceProblems (dupInstall bareSys ffNixosMods pk.firefox) "firefox");
      "control(browser): the vanilla twin has no thunderbird mailto" =
        detects "thunderbird on vanilla" (mimeProblems vanilla [ "x-scheme-handler/mailto" ] "thunderbird.desktop");
    };
    warnings = {
      "unknown browser: nothing installed, exactly one warning for it" =
        failIf (loneWarnProblems unknownBrowser "browser" "no-such-browser-xyz"
          ++ lib.optional (installs unknownBrowser "no-such-browser-xyz" != 0) "unknown name installed");
      "unknown browser and file manager: one warning per role" =
        eq "warning count" (builtins.length (warnsOf unknownTwo)) 2;
      "unknown editor: exactly one warning" =
        failIf (loneWarnProblems unknownEditor "editor" "no-such-editor-xyz");
      "zen-beta with the module off: nothing installed, exactly one warning" =
        failIf (loneWarnProblems zenNoModule "browser" "zen-beta" ++ lib.optional (installs zenNoModule "zen-beta" != 0) "zen-beta installed");
      "wrapper in home.packages (brave-school style): installed once, no warning" =
        failIf (onceProblems schoolWrapper "brave-school" ++ quietProblems schoolWrapper);
      "control(warnings): a second unknown role is flagged by the lone-warning check" =
        detects "extra warning" (loneWarnProblems unknownTwo "browser" "no-such-browser-xyz");
      "control(warnings): the quiet check sees the unknown-name warning" =
        detects "warning" (quietProblems unknownBrowser);
    };
    media = {
      "vanilla: media defaults (video/audio mpv, pdf zathura, office writer/calc/impress, archives ark), no warning" =
        failIf (mimeProblems vanilla videoTypes "mpv.desktop" ++ mimeProblems vanilla audioTypes "mpv.desktop"
          ++ mimeProblems vanilla pdfTypes "org.pwmt.zathura.desktop"
          ++ mimeProblems vanilla docTypes "writer.desktop" ++ mimeProblems vanilla sheetTypes "calc.desktop"
          ++ mimeProblems vanilla slideTypes "impress.desktop" ++ mimeProblems vanilla archiveTypes "org.kde.ark.desktop"
          ++ quietProblems vanilla);
      "videoPlayer/audioPlayer vlc: vlc installed once, vlc.desktop for video and audio, no warning" =
        failIf (onceProblems vlcVideo "vlc" ++ mimeProblems vlcVideo (videoTypes ++ audioTypes) "vlc.desktop" ++ quietProblems vlcVideo);
      "flatpak id present in services.flatpak.packages: used as <id>.desktop, nothing installed for it, no warning" =
        failIf (mimeProblems craftPresent docTypes "ai.storyteller.wordcraft.desktop" ++ mimeProblems craftPresent sheetTypes "ai.storyteller.gridcraft.desktop"
          ++ mimeProblems craftPresent slideTypes "impress.desktop" ++ quietProblems craftPresent
          ++ lib.optional (installs craftPresent "wordcraft" != 0) "wordcraft installed");
      "flatpak id missing from services.flatpak.packages: falls back to the bare default with one warning per role" =
        all [
          (failIf (mimeProblems craftMissing docTypes "writer.desktop" ++ mimeProblems craftMissing sheetTypes "calc.desktop"))
          (eq "warning count" (builtins.length (warnsOf craftMissing)) 2)
          (eq "docEditor warned once" (builtins.length (builtins.filter (lib.hasInfix "mime: docEditor = \"ai.storyteller.wordcraft\"") (warnsOf craftMissing))) 1)
        ];
      "unknown videoPlayer: falls back to mpv.desktop with exactly one warning" =
        failIf (mimeProblems unknownVideo videoTypes "mpv.desktop" ++ loneWarnProblems unknownVideo "videoPlayer" "no-such-player-xyz");
      "vanilla: bare role apps (mpv, libreoffice, zathura, ark, gwenview) installed exactly once, shared roles not doubled" =
        failIf (allOnce vanilla [ mpvName "libreoffice" zathuraName "ark" "gwenview" ]);
      "vanilla: extra image types (avif bmp tiff svg heic jxl psd xcf dng RAW) -> gwenview" =
        failIf (mimeProblems vanilla imageExtraTypes "org.kde.gwenview.desktop");
      "explicit mpv equals the default: no warning, mpv still once" =
        failIf (onceProblems mpvExplicit mpvName ++ mimeProblems mpvExplicit (videoTypes ++ audioTypes) "mpv.desktop" ++ quietProblems mpvExplicit);
      "control(media): the vanilla twin does not satisfy the vlc expectation" =
        detects "vlc on vanilla" (mimeProblems vanilla videoTypes "vlc.desktop");
      "control(media): the flatpak-missing twin does not satisfy the flatpak-present expectation" =
        detects "wordcraft on missing" (mimeProblems craftMissing docTypes "ai.storyteller.wordcraft.desktop");
    };
    roles = {
      "pdfViewer okular (kdePackages): okular once, zathura not installed, org.kde.okular.desktop, no warning" =
        failIf (onceProblems pdfOkular "okular" ++ mimeProblems pdfOkular pdfTypes "org.kde.okular.desktop" ++ quietProblems pdfOkular
          ++ lib.optional (installs pdfOkular zathuraName != 0) "zathura still installed");
      "archiveManager file-roller: file-roller once, ark not installed, org.gnome.FileRoller.desktop, no warning" =
        failIf (onceProblems archiveFileRoller "file-roller" ++ mimeProblems archiveFileRoller archiveTypes "org.gnome.FileRoller.desktop" ++ quietProblems archiveFileRoller
          ++ lib.optional (installs archiveFileRoller "ark" != 0) "ark still installed");
      "archiveManager xarchiver (name without a table entry): xarchiver once, xarchiver.desktop, ark not installed, no warning" =
        failIf (onceProblems archiveXarchiver "xarchiver" ++ mimeProblems archiveXarchiver archiveTypes "xarchiver.desktop" ++ quietProblems archiveXarchiver
          ++ lib.optional (installs archiveXarchiver "ark" != 0) "ark still installed");
      "pdfViewer zathura via home-manager programs.zathura.enable: still exactly one zathura, no warning" =
        failIf (onceProblems zathuraHm zathuraName ++ mimeProblems zathuraHm pdfTypes "org.pwmt.zathura.desktop" ++ quietProblems zathuraHm);
      "videoPlayer wrapper in home.packages: <name>.desktop, installed once, no warning, audio keeps mpv" =
        failIf (onceProblems playerWrapper "my-player" ++ mimeProblems playerWrapper videoTypes "my-player.desktop"
          ++ mimeProblems playerWrapper audioTypes "mpv.desktop" ++ quietProblems playerWrapper);
      "all three office roles on present flatpak ids: libreoffice is not installed at all" =
        failIf (mimeProblems officeCraft slideTypes "ai.storyteller.deckcraft.desktop" ++ mimeProblems officeCraft sheetTypes "ai.storyteller.gridcraft.desktop"
          ++ mimeProblems officeCraft docTypes "ai.storyteller.wordcraft.desktop" ++ quietProblems officeCraft
          ++ lib.optional (installs officeCraft "libreoffice" != 0) "libreoffice installed ${toString (installs officeCraft "libreoffice")} times");
      "imageViewer on a present flatpak id: every image type -> <id>.desktop, gwenview not installed, no warning" =
        failIf (mimeProblems imageCraft (imageTypes ++ imageExtraTypes) "ai.storyteller.photocraft.desktop" ++ quietProblems imageCraft
          ++ lib.optional (installs imageCraft "gwenview" != 0) "gwenview still installed");
      "imageViewer on a missing flatpak id: gwenview for every image type, one warning" =
        failIf (mimeProblems imageCraftMissing (imageTypes ++ imageExtraTypes) "org.kde.gwenview.desktop" ++ onceProblems imageCraftMissing "gwenview"
          ++ loneWarnProblems imageCraftMissing "imageViewer" "ai.storyteller.photocraft");
      "unknown archiveManager: falls back to org.kde.ark.desktop with exactly one warning" =
        failIf (mimeProblems unknownArchive archiveTypes "org.kde.ark.desktop" ++ onceProblems unknownArchive "ark"
          ++ loneWarnProblems unknownArchive "archiveManager" "no-such-archiver-xyz");
      "every role unknown: each falls back to its bare default, exactly one warning per role" =
        all [
          (failIf (mimeProblems allUnknown (videoTypes ++ audioTypes) "mpv.desktop" ++ mimeProblems allUnknown (imageTypes ++ imageExtraTypes) "org.kde.gwenview.desktop"
            ++ mimeProblems allUnknown pdfTypes "org.pwmt.zathura.desktop" ++ mimeProblems allUnknown docTypes "writer.desktop"
            ++ mimeProblems allUnknown sheetTypes "calc.desktop" ++ mimeProblems allUnknown slideTypes "impress.desktop"
            ++ mimeProblems allUnknown archiveTypes "org.kde.ark.desktop" ++ allOnce allUnknown [ mpvName "libreoffice" zathuraName "ark" "gwenview" ]))
          (eq "warning count" (builtins.length (warnsOf allUnknown)) (builtins.length roleNames))
          (all (map (r: eq "${r} warned once" (builtins.length (builtins.filter (lib.hasInfix "mime: ${r} = ") (warnsOf allUnknown))) 1) roleNames))
        ];
    };
    roleControls = {
      "control(roles): a second mpv install is detected" =
        detects "two mpv" (onceProblems (dupInstall bareSys [ ] pk.mpv) mpvName);
      "control(roles): a second zathura on top of the home-manager module is detected" =
        detects "two zathura" (onceProblems (dupInstall bareSys [ zathuraHmMod ] pk.zathura) zathuraName);
      "control(roles): the okular twin does not satisfy the zathura expectation, the vanilla twin not the okular one" =
        all [ (detects "okular on zathura" (mimeProblems pdfOkular pdfTypes "org.pwmt.zathura.desktop")) (detects "zathura on okular" (mimeProblems vanilla pdfTypes "org.kde.okular.desktop")) ];
      "control(roles): the photocraft twin does not satisfy the gwenview expectation" =
        detects "photocraft on gwenview" (mimeProblems imageCraft imageExtraTypes "org.kde.gwenview.desktop");
      "control(roles): vanilla does install libreoffice (so the flatpak twin's absence is real)" =
        eq "libreoffice installs" (installs vanilla "libreoffice") 1;
      "control(roles): the quiet check and the unknown-role count see the all-unknown twin" =
        all [ (detects "warning" (quietProblems allUnknown)) (detects "warning-count" (lib.optional (builtins.length (warnsOf allUnknown) != 1) "not one")) ];

      "removed option programs.file-roller: reading it throws, yet archiveManager = file-roller still evaluates warnings and packages" =
        all [
          (eq "reading the removed option throws" (builtins.tryEval archiveFileRoller.programs.file-roller.enable).success false)
          (eq "warnings and packages evaluate" (safeEval [ archiveFileRoller.warnings (names archiveFileRoller) ]) true)
        ];
      "control(removed option): a declared programs.<n>.enable reads fine, so the throw above is specific to the removed option" =
        eq "programs.firefox.enable readable" (builtins.tryEval vanilla.programs.firefox.enable).success true;
    };
    extras = {
      "extraAppPackages name in pkgs: installed exactly once, no warning" =
        failIf (onceProblems extraHello "hello" ++ quietProblems extraHello);
      "extraAppPackages name only in pkgs.kdePackages (kate): installed exactly once, no warning" =
        failIf (onceProblems extraKate "kate" ++ quietProblems extraKate);
      "control(extras): the vanilla twin installs neither hello nor kate" =
        all [ (eq "hello" (installs vanilla "hello") 0) (eq "kate" (installs vanilla "kate") 0) ];
      "control(extras): kate is not a top-level pkgs attribute, so the kdePackages fallback is what resolves it" =
        eq "pkgs ? kate" (pk ? kate) false;
      "unknown extraAppPackages name: exactly one extraAppPackages warning naming it, nothing installed" =
        all [
          (eq "extras warning count" (builtins.length (extraWarnsOf extraUnknown)) 1)
          (failIf (lib.optional (!(lib.hasInfix "no-such-extra-xyz" (lib.head (extraWarnsOf extraUnknown ++ [ "" ])))) "warning does not name the package"
            ++ lib.optional (installs extraUnknown "no-such-extra-xyz" != 0) "unknown name installed"
            ++ lib.optional (builtins.length (warnsOf extraUnknown) != 1) "unrelated warnings: ${builtins.toJSON (warnsOf extraUnknown)}"))
        ];
      "control(extras): the vanilla twin has no extraAppPackages warning, and the quiet check sees the unknown-extra warning" =
        all [ (eq "vanilla extras warnings" (extraWarnsOf vanilla) [ ]) (detects "extra warning" (quietProblems extraUnknown)) ];
      "mixed extraAppPackages (resolvable, duplicate, two unknown): hello once, one warning listing both unknown names and not hello" =
        all [
          (failIf (onceProblems extraMixed "hello"))
          (eq "extras warning count" (builtins.length (extraWarnsOf extraMixed)) 1)
          (failIf (lib.optional (!(lib.hasInfix "no-such-extra-a, no-such-extra-b" (lib.head (extraWarnsOf extraMixed ++ [ "" ])))) "warning does not list both unknown names in order"
            ++ lib.optional (lib.hasInfix "(hello" (lib.head (extraWarnsOf extraMixed ++ [ "" ]))) "warning lists the resolvable name"))
        ];
      "extraAppPackages dedupe against the role installs: mpv named as an extra is still installed exactly once, no warning" =
        failIf (onceProblems extraMpv mpvName ++ quietProblems extraMpv);
      "extraAppPackages dedupe against a home-manager program: zathura (programs.zathura.enable) named as an extra stays exactly one" =
        failIf (onceProblems extraZathuraHm zathuraName ++ quietProblems extraZathuraHm);
      "extraAppPackages name provided by a home.packages wrapper: installed once, no unresolved warning" =
        failIf (onceProblems extraWrapper "my-extra-wrapper" ++ quietProblems extraWrapper);
      "control(extras): a forced second mpv on top of the extras twin is detected" =
        detects "two mpv" (onceProblems (dupInstall bareSys [ (mimeOpts { extraAppPackages = [ "mpv" ]; }) ] pk.mpv) mpvName);
    };
    desktopRoles = {
      "role = org.kde.kate.desktop with extraAppPackages = [ kate ]: mapped verbatim, kate installed once, libreoffice still once for sheet and slide, no warning" =
        failIf (mimeProblems kateRole docTypes kateDesktop ++ onceProblems kateRole "kate" ++ onceProblems kateRole "libreoffice"
          ++ mimeProblems kateRole sheetTypes "calc.desktop" ++ quietProblems kateRole);
      "role = org.kde.kate.desktop without extraAppPackages: falls back to writer.desktop with exactly one warning, kate not installed" =
        failIf (mimeProblems kateRoleNoExtra docTypes "writer.desktop" ++ loneWarnProblems kateRoleNoExtra "docEditor" kateDesktop
          ++ lib.optional (installs kateRoleNoExtra "kate" != 0) "kate installed"
          ++ lib.optional (!(lib.hasInfix "extraAppPackages" (lib.head (warnsOf kateRoleNoExtra ++ [ "" ])))) "warning does not point at extraAppPackages");
      "role = org.kde.kate.desktop with an unrelated extra (hello): falls back with exactly one warning, hello installed, kate not" =
        failIf (mimeProblems kateRoleWrongExtra docTypes "writer.desktop" ++ loneWarnProblems kateRoleWrongExtra "docEditor" kateDesktop
          ++ onceProblems kateRoleWrongExtra "hello" ++ lib.optional (installs kateRoleWrongExtra "kate" != 0) "kate installed");
      "role = <flatpak id>.desktop with the id in services.flatpak.packages: mapped verbatim, nothing installed, no warning" =
        failIf (mimeProblems craftDesktopPresent docTypes "ai.storyteller.wordcraft.desktop" ++ quietProblems craftDesktopPresent
          ++ lib.optional (installs craftDesktopPresent "wordcraft" != 0) "wordcraft installed");
      "role = <flatpak id>.desktop with the id missing from services.flatpak.packages: falls back to writer.desktop with one warning" =
        failIf (mimeProblems craftDesktopMissing docTypes "writer.desktop" ++ loneWarnProblems craftDesktopMissing "docEditor" "ai.storyteller.wordcraft.desktop");
      "archiveManager = org.gnome.FileRoller.desktop with extraAppPackages = [ file-roller ]: verbatim id, file-roller once (removed program option ignored), ark not installed, no warning" =
        failIf (mimeProblems rollerDesktop archiveTypes "org.gnome.FileRoller.desktop" ++ onceProblems rollerDesktop "file-roller"
          ++ lib.optional (installs rollerDesktop "ark" != 0) "ark still installed" ++ quietProblems rollerDesktop);
      "control(desktop roles): the fallback twin does not satisfy the kate expectation, the kate twin not the writer one, the extras-only twin not the kate one" =
        all [
          (detects "kate on no-extra" (mimeProblems kateRoleNoExtra docTypes kateDesktop))
          (detects "writer on kate" (mimeProblems kateRole docTypes "writer.desktop"))
          (detects "kate on extras-only" (mimeProblems extraKate docTypes kateDesktop))
          (detects "wordcraft on missing flatpak" (mimeProblems craftDesktopMissing docTypes "ai.storyteller.wordcraft.desktop"))
        ];
      "control(desktop roles): the kate twin warns neither, while the fallback twin trips the quiet check" =
        all [ (eq "kate quiet" (warnsOf kateRole) [ ]) (detects "fallback warning" (quietProblems kateRoleNoExtra)) ];
    };
    mime = {
      "mime: mimeapps.list is forced" = eq "force" (forceOf vanilla) true;
      "control(mime): mime module off does not force mimeapps.list" = eq "force" (forceOf mimeOff != true) true;
    };
  };

  checks = lib.foldl' (acc: g: acc // g) { } (builtins.attrValues groups);
  checkCount = lib.foldl' (n: g: n + builtins.length (builtins.attrNames g)) 0 (builtins.attrValues groups);

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  groupNames =
    if checkCount == builtins.length (builtins.attrNames checks) then builtins.attrNames groups
    else throw "check labels repeated across groups: ${toString checkCount} declared, ${toString (builtins.length (builtins.attrNames checks))} unique";
  groupResults = name: lib.mapAttrs (_: safe) groups.${name};
}
