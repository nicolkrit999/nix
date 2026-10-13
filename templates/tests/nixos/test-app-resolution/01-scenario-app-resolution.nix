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

  hm = c: c.home-manager.users.krit;
  names = c: map lib.getName (c.environment.systemPackages ++ (hm c).home.packages);
  installs = c: n: builtins.length (builtins.filter (x: x == n) (names c));
  entries = c: builtins.attrNames (hm c).xdg.desktopEntries;
  mimeOf = c: k: lib.toList (hm c).xdg.mimeApps.defaultApplications.${k};
  textTypes = [ "text/plain" "text/markdown" "application/x-shellscript" "application/json" "text/x-nix" ];
  browserTypes = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" "x-scheme-handler/about" "x-scheme-handler/unknown" "application/pdf" ];
  warnsOf = c: builtins.filter (lib.hasPrefix "home-packages: constants ") c.warnings;

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
      mine = builtins.filter (lib.hasInfix "constants ${role} = \"${name}\"") ws;
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
  unknownEditor = twin bareSys [ (constants { editor = "no-such-editor-xyz"; }) ];

  mailThunderbird = twin bareSys [{ myconfig.programs.thunderbird.enable = true; }];
  braveBrowser = twin bareSys [ (constants { browser = "brave"; }) ];
  chromeBrowser = twin bareSys [ (constants { browser = "chrome"; }) ];
  fooTerm = twin bareSys [{ myconfig.constants.terminal.name = mk "foot"; }];
  helixEd = twin bareSys [ (constants { editor = "helix"; }) ];
  codeEd = twin bareSys [ (constants { editor = "code"; }) ];
  mimeOff = twin bareSys [{ myconfig.mime.enable = mk false; }];
  homePkgsOff = twin bareSys [{ myconfig.home-packages.enable = mk false; }];

  allOnce = c: ns: lib.concatMap (onceProblems c) ns;
  execOf = c: e: (hm c).xdg.desktopEntries.${e}.exec;
  forceOf = c: (hm c).xdg.configFile."mimeapps.list".force or false;

  checks = {
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
        ++ mimeProblems vanilla [ "image/jpeg" "image/png" "image/gif" "image/webp" ] "org.kde.gwenview.desktop");
    "control(once): a second install is detected" =
      detects "two chromium" (onceProblems (dupInstall bareSys [ ] pk.chromium) "chromium");
    "control(once): home-packages disabled installs nothing" =
      detects "no chromium" (onceProblems homePkgsOff "chromium");

    "editor vim: user-vim exec uses terminal.name" =
      eq "exec" (execOf vanilla "user-vim") "kitty -e vim %F";
    "editor vim: terminal foot changes the exec (control: not hardcoded)" =
      all [ (eq "exec" (execOf fooTerm "user-vim") "foot -e vim %F") (eq "kitty exec differs" (execOf fooTerm "user-vim" != execOf vanilla "user-vim") true) ];
    "editor helix: user-helix entry runs hx in the terminal" =
      all [ (failIf (entryProblems helixEd [ "user-helix" ] [ "user-vim" ] ++ mimeProblems helixEd textTypes "user-helix.desktop")) (eq "exec" (execOf helixEd "user-helix") "kitty -e hx %F") ];
    "editor code: code.desktop, no user entry" =
      failIf (entryProblems codeEd [ ] [ "user-code" ] ++ mimeProblems codeEd textTypes "code.desktop");

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

    "fileManager dolphin with the krit dolphin module: one dolphin, org.kde.dolphin.desktop, no warning" =
      failIf (onceProblems dolphinKrit "dolphin" ++ mimeProblems dolphinKrit [ "inode/directory" ] "org.kde.dolphin.desktop" ++ quietProblems dolphinKrit);
    "fileManager dolphin without the krit tree: one dolphin, org.kde.dolphin.desktop" =
      failIf (onceProblems dolphinBare "dolphin" ++ mimeProblems dolphinBare [ "inode/directory" ] "org.kde.dolphin.desktop" ++ quietProblems dolphinBare);
    "control(fileManager): a second dolphin install is detected" =
      detects "two dolphin" (onceProblems (dupInstall kritSys dolphinKritMods pk.kdePackages.dolphin) "dolphin");

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

    "mime: mimeapps.list is forced" = eq "force" (forceOf vanilla) true;
    "control(mime): mime module off does not force mimeapps.list" = eq "force" (forceOf mimeOff != true) true;
  };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
