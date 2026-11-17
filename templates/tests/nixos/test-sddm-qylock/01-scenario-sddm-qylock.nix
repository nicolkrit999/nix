let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  lib = flake.inputs.nixpkgs.lib;
  denix = flake.inputs.denix;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  here = src + "/templates/tests/nixos/test-sddm-qylock";
  noContext = builtins.unsafeDiscardStringContext;

  fakeHosts = denix.lib.configurations {
    moduleSystem = "nixos";
    homeManagerUser = "krit";
    extensions = with denix.lib.extensions; [
      args
      (base.withConfig {
        args.enable = true;
        rices.enable = false;
      })
    ];
    specialArgs = {
      inherit (flake) inputs;
      moduleSystem = "nixos";
    };
    paths = [
      (here + "/host")
      (here + "/nixos-extra")
      (src + "/modules/nixos/toplevel/home-manager.nix")
      (src + "/modules/nixos/config/constants-nixos.nix")
      (src + "/modules/common/config/constants.nix")
      (src + "/modules/nixos/services/sddm/sddm-qylock.nix")
    ];
    exclude = [ ];
  };
  fakeHost = fakeHosts.${builtins.head (builtins.attrNames fakeHosts)};

  video = name: color: pkgs.runCommand "${name}.mp4" { nativeBuildInputs = [ pkgs.ffmpeg-headless ]; } ''
    ffmpeg -loglevel error -f lavfi -i color=c=${color}:s=64x64:r=5:d=1 -c:v mpeg4 -pix_fmt yuv420p -f mp4 $out
  '';
  image = name: color: pkgs.runCommand "${name}.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick -size 64x64 xc:'${color}' png:$out
  '';
  fixtures = {
    video-black = video "video-black" "black";
    video-white = video "video-white" "white";
    image-grey = image "image-grey" "#c0c0c0";
  };
  assetsDir = pkgs.runCommand "sddm-assets" { } ''
    mkdir $out
    cp ${fixtures.image-grey} $out/plain-name.png
  '';

  scenario = cfg: fakeHost.extendModules {
    modules = [{
      myconfig.services.sddm-qylock = lib.mapAttrs (_: v: lib.mkOverride 10 v) cfg;
    }];
  };

  built = {
    default = { };
    h24 = { use24HourClock = true; };
    vid-explicit = { background = fixtures.video-black; backgroundDim = "0.4"; };
    vid-auto-black = { background = fixtures.video-black; };
    vid-auto-white = { background = fixtures.video-white; };
    img-explicit = { theme = "nier-automata"; use24HourClock = true; background = "plain-name.png"; inherit assetsDir; backgroundDim = "0.5"; };
    terraria-opt = { theme = "terraria"; use24HourClock = true; themeOptions.terraria.backgroundMode = "time"; };
    terraria-plain = { theme = "terraria"; use24HourClock = true; };
    nier-12h = { theme = "nier-automata"; };
    terraria-12h = { theme = "terraria"; };
  };

  errors = {
    kind-video-theme-image = { background = fixtures.image-grey; };
    kind-image-theme-video = { theme = "nier-automata"; use24HourClock = true; background = fixtures.video-black; };
    unsupported-genshin = { theme = "Genshin"; use24HourClock = true; background = fixtures.video-black; };
    missing-file = { background = "missing-file.mp4"; inherit assetsDir; };
    absolute-path = { background = "/etc/hostname"; };
  };

  pkgOf = s: lib.findFirst (p: lib.hasPrefix "sddm-qylock-" (p.name or "")) null s.config.environment.systemPackages;
  scenarios = lib.mapAttrs (_: scenario) built;
  upstreamThemes = pkgs.runCommandLocal "qylock-upstream-themes" { } "ln -s ${flake.inputs.qylock}/themes $out";
in
{
  matrix = lib.mapAttrs
    (_: s: {
      theme = s.config.services.displayManager.sddm.theme;
      pkgName = (pkgOf s).name;
      drvPath = noContext (pkgOf s).drvPath;
    })
    scenarios;
  fixtures = lib.mapAttrs (_: d: noContext "${d}") fixtures;
  themesSrc = noContext "${upstreamThemes}";
  assetsDir = noContext "${assetsDir}";
  tools.magick = noContext "${pkgs.imagemagick}/bin/magick";
  pkg = lib.mapAttrs (_: pkgOf) scenarios // lib.mapAttrs (_n: d: d) fixtures // { assets = assetsDir; upstream-themes = upstreamThemes; };
  err = lib.mapAttrs (_: cfg: (pkgOf (scenario cfg)).drvPath) errors;
  errIds = builtins.attrNames errors;
}
