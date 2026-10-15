{ host }:
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  sys = flake.nixosConfigurations.${host};
  base = sys.config;
  user = base.myconfig.constants.user;
  hm = c: c.home-manager.users.${user};
  defaults = c: (hm c).xdg.mimeApps.defaultApplications;
  mimeOf = c: t: lib.toList ((defaults c).${t} or [ ]);
  constantOf = c: role: c.myconfig.constants.${role};

  types = {
    videoPlayer = [ "video/mp4" "video/x-m4v" "video/quicktime" "video/x-matroska" "video/webm" "video/vnd.avi" "video/x-msvideo" "video/mp2t" "video/mpeg" "video/3gpp" "video/ogg" "video/x-flv" "application/mxf" ];
    audioPlayer = [ "audio/mpeg" "audio/mp3" "audio/mp4" "audio/x-m4a" "audio/aac" "audio/flac" "audio/ogg" "audio/vorbis" "audio/opus" "audio/x-wav" "audio/webm" "audio/x-matroska" "audio/x-ms-wma" "audio/x-aiff" "audio/x-ape" "audio/x-wavpack" "audio/x-mpegurl" "audio/x-scpls" "application/ogg" ];
    imageViewer = [ "image/jpeg" "image/png" "image/gif" "image/webp" "image/avif" "image/bmp" "image/tiff" "image/x-icon" "image/svg+xml" "image/heic" "image/jxl" "image/vnd.adobe.photoshop" "image/x-xcf" "image/x-adobe-dng" "image/x-canon-cr2" "image/x-nikon-nef" "image/x-sony-arw" ];
    pdfViewer = [ "application/pdf" ];
    docEditor = [ "application/vnd.openxmlformats-officedocument.wordprocessingml.document" "application/vnd.oasis.opendocument.text" "application/msword" "application/rtf" "text/rtf" ];
    sheetEditor = [ "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" "application/vnd.oasis.opendocument.spreadsheet" "application/vnd.ms-excel" "text/csv" ];
    slideEditor = [ "application/vnd.openxmlformats-officedocument.presentationml.presentation" "application/vnd.oasis.opendocument.presentation" "application/vnd.ms-powerpoint" ];
    archiveManager = [ "application/zip" "application/x-tar" "application/gzip" "application/x-xz" "application/x-bzip2" "application/zstd" "application/x-compressed-tar" "application/x-7z-compressed" "application/vnd.rar" ];
  };
  roles = builtins.attrNames types;

  isFlatpakId = name: builtins.match "[A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+){2,}" name != null;
  flatpakIdsOf = c: map (p: if builtins.isAttrs p then p.appId else p) c.services.flatpak.packages;
  stem = id: lib.removeSuffix ".desktop" id;
  craftPrefix = "ai.storyteller.";

  profilePackages = c: builtins.filter (p: builtins.isAttrs p && (p ? name || p ? pname))
    (c.environment.systemPackages ++ c.users.users.${user}.packages ++ (hm c).home.packages);
  candidates = c: name: builtins.filter (p: let n = lib.getName p; in n == name || lib.hasPrefix "${name}-" n) (profilePackages c);
  shipsDesktop = pkgs: id: builtins.any (p: builtins.any (o: builtins.pathExists "${p.${o}}/share/applications/${id}") p.outputs) pkgs;

  ok = "ok";
  failIf = problems: if problems == [ ] then ok else "FAIL: ${builtins.concatStringsSep "; " problems}";
  detects = what: problems: if problems != [ ] then ok else "FAIL: control did not detect: ${what}";
  eq = what: got: want: if got == want then ok else "FAIL: ${what}: got ${builtins.toJSON got}, expected ${builtins.toJSON want}";
  all = xs: failIf (builtins.filter (x: x != ok) xs);

  missingProblems = c: ts: lib.concatMap (t: lib.optional (mimeOf c t == [ ]) "${t} has no explicit default") ts;
  idsOf = c: ts: lib.unique (lib.concatMap (t: mimeOf c t) ts);
  singleIdProblems = c: role:
    let ids = idsOf c types.${role}; in
    lib.optional (builtins.length ids > 1) "${role} types resolve to several apps: ${builtins.toJSON ids}";
  flatpakProblems = c: role: id:
    let want = constantOf c role; in
    if isFlatpakId want then
      lib.optional (id != "${want}.desktop") "${role} = ${want} but the types resolve to ${id}"
      ++ lib.optional (!(builtins.elem want (flatpakIdsOf c))) "${want} is not in the host's flatpak list"
    else
      lib.optional (builtins.elem (stem id) (flatpakIdsOf c)) "${role} = ${want} but the types resolve to the flatpak ${id}";
  rolesProblems = c: role: flatpakProblems c role (lib.head (idsOf c types.${role} ++ [ "none" ]));
  prefixProblems = c: prefix: role:
    let
      keys = builtins.filter (lib.hasPrefix prefix) (builtins.attrNames (defaults c));
      want = idsOf c types.${role};
    in
    lib.concatMap (t: lib.optional (mimeOf c t != want) "${t} -> ${builtins.toJSON (mimeOf c t)}, expected ${builtins.toJSON want}") keys;
  craftProblems = c: ts: lib.concatMap (t: lib.optional (lib.any (lib.hasPrefix craftPrefix) (mimeOf c t)) "${t} -> ${builtins.toJSON (mimeOf c t)}") ts;
  warnsOf = c: builtins.filter (w: lib.hasPrefix "mime: constants " w || lib.hasPrefix "home-packages: constants " w) c.warnings;

  unknownVideo = (sys.extendModules { modules = [{ myconfig.constants.videoPlayer = lib.mkForce "no-such-player-xyz"; }]; }).config;
  filmcraftMp4 = (sys.extendModules {
    modules = [{ home-manager.users.${user}.xdg.mimeApps.defaultApplications."video/mp4" = lib.mkForce "ai.storyteller.filmcraft.desktop"; }];
  }).config;

  checks = {
    "no role fell back: no mime / home-packages constants warning" = failIf (map (w: "unexpected warning: ${w}") (warnsOf base));
    "control: an unknown videoPlayer produces the fallback warning" = detects "warning" (warnsOf unknownVideo);
    "control: the unknown videoPlayer falls back to the bare default mpv.desktop" = eq "video/mp4" (mimeOf unknownVideo "video/mp4") [ "mpv.desktop" ];

    "video/mp4 is never a Craft app (the Filmcraft bug)" = failIf (craftProblems base [ "video/mp4" ]);
    "control: the Craft check sees video/mp4 forced to Filmcraft" = detects "filmcraft" (craftProblems filmcraftMp4 [ "video/mp4" ]);
    "video, audio and image types never resolve to a Craft app unless the host chose one for that role" =
      failIf (lib.concatMap (r: lib.optionals (!(isFlatpakId (constantOf base r))) (craftProblems base types.${r})) [ "videoPlayer" "audioPlayer" "imageViewer" "pdfViewer" "archiveManager" ]);

    "every video/ and audio/ default maps to its role's app" =
      failIf (prefixProblems base "video/" "videoPlayer" ++ prefixProblems base "audio/" "audioPlayer");
    "every image/ default and application/pdf map to their role's app" =
      failIf (prefixProblems base "image/" "imageViewer" ++ prefixProblems base "application/pdf" "pdfViewer");
    "control: the prefix check sees mp4 forced away from the video role" =
      detects "prefix" (prefixProblems filmcraftMp4 "video/" "videoPlayer");

    "control: an unowned type is reported as missing" = detects "missing" (missingProblems base [ "video/x-no-such-type" ]);
    "control: a flatpak id missing from the host list is reported" =
      detects "flatpak" (flatpakProblems base "docEditor" "ai.storyteller.no-such-app.desktop");
    "control: a package role that resolves to a flatpak id is reported" =
      detects "flatpak for package" (flatpakProblems base "imageViewer" "ai.storyteller.photocraft.desktop");
    "control: a role whose types resolve to two apps is reported" =
      detects "two apps" (singleIdProblems filmcraftMp4 "videoPlayer");

    "host contract (user decision): video and audio -> vlc.desktop" =
      all [ (eq "video/mp4" (mimeOf base "video/mp4") [ "vlc.desktop" ]) (eq "audio/flac" (mimeOf base "audio/flac") [ "vlc.desktop" ]) ];
    "host contract (user decision): docx / xlsx / pptx -> wordcraft / gridcraft / deckcraft" =
      all [
        (eq "docx" (mimeOf base "application/vnd.openxmlformats-officedocument.wordprocessingml.document") [ "ai.storyteller.wordcraft.desktop" ])
        (eq "xlsx" (mimeOf base "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet") [ "ai.storyteller.gridcraft.desktop" ])
        (eq "pptx" (mimeOf base "application/vnd.openxmlformats-officedocument.presentationml.presentation") [ "ai.storyteller.deckcraft.desktop" ])
      ];
    "host contract (user decision): image types go to Gwenview, not to a Craft app" =
      failIf (craftProblems base types.imageViewer ++ lib.concatMap (t: lib.optional (mimeOf base t != [ "org.kde.gwenview.desktop" ]) "${t} -> ${builtins.toJSON (mimeOf base t)}") types.imageViewer);
  }
  // lib.listToAttrs (map (r: lib.nameValuePair "${r}: every owned type has an explicit default" (failIf (missingProblems base types.${r}))) roles)
  // lib.listToAttrs (map (r: lib.nameValuePair "${r}: one app for all types, flatpak id consistent with the constant and the host's flatpak list" (failIf (singleIdProblems base r ++ rolesProblems base r))) roles);

  profileProblems = c: role:
    let
      id = lib.head (idsOf c types.${role} ++ [ "none" ]);
      want = constantOf c role;
    in
    if isFlatpakId want then
      lib.optional (!(builtins.elem want (flatpakIdsOf c))) "${want} not in the host's flatpak list"
    else if candidates c want == [ ] then [ "no package named ${want} in the host's profile" ]
    else lib.optional (!(shipsDesktop (candidates c want) id)) "${id} is not shipped by the ${want} packages";

  profileChecks = {
    "control: a desktop id nothing ships is detected" =
      detects "bogus id" (lib.optional (!(shipsDesktop (candidates base (constantOf base "videoPlayer")) "no-such-app.desktop")) "absent");
    "control: a package name nothing provides has no candidates" = detects "no candidates" (lib.optional (candidates base "no-such-package-xyz" == [ ]) "none");
  }
  // lib.listToAttrs (map (r: lib.nameValuePair "${r}: the default .desktop id exists in the built profile or the flatpak list" (failIf (profileProblems base r))) roles);

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks profileChecks;
  results = lib.mapAttrs (_: safe) checks;
  profileResults = lib.mapAttrs (_: safe) profileChecks;
  mimeappsList = builtins.readFile (hm base).xdg.configFile."mimeapps.list".source;
}
