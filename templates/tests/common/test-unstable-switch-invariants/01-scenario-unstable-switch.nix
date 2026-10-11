let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hasNixos = flake.nixosConfigurations != { };
  nixosHost = flake.nixosConfigurations.template-host-minimal;
  darwinHost = flake.darwinConfigurations.Krits-MacBook-Pro;

  guard = body: if hasNixos then body else "ok";

  expect = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  withModules = host: modules: host.extendModules { inherit modules; };

  pkgsStableProbe = host: hmUser:
    let
      x = withModules host [
        ({ pkgsStable, ... }: {
          environment.etc."probe-sys".text = pkgsStable.stdenv.hostPlatform.system;
          environment.etc."probe-sys-ver".text = toString pkgsStable.path;
        })
        {
          home-manager.users.${hmUser} = { pkgsStable, ... }: {
            home.file."probe-hm".text = pkgsStable.stdenv.hostPlatform.system;
            home.file."probe-hm-ver".text = toString pkgsStable.path;
          };
        }
      ];
    in
    {
      sys = x.config.environment.etc."probe-sys".text;
      hm = x.config.home-manager.users.${hmUser}.home.file."probe-hm".text;
      sysVer = x.config.environment.etc."probe-sys-ver".text;
      hmVer = x.config.home-manager.users.${hmUser}.home.file."probe-hm-ver".text;
    };

  atuinFor = shell: atuinWith true shell;

  atuinWith = enabled: shell:
    let
      x = withModules nixosHost [
        ({ lib, ... }: {
          myconfig.programs.atuin.enable = enabled;
          myconfig.constants.shell = lib.mkForce shell;
        })
      ];
      h = x.config.home-manager.users.krit;
    in
    {
      flags = h.programs.atuin.flags;
      bash = h.programs.bash.initExtra;
      zsh = h.programs.zsh.initContent;
      fish = h.programs.fish.interactiveShellInit;
    };

  has = needle: hay: lib.hasInfix needle hay;
  hasLine = needle: hay:
    builtins.any (l: lib.trim l == needle) (lib.splitString "\n" hay);

  vicinaeHm = hmOf (withModules nixosHost [{ myconfig.programs.vicinae.enable = true; }]);
  stableVer = toString flake.inputs.nixpkgs-stable.outPath;
  mainVer = toString flake.inputs.nixpkgs.outPath;
  pkgsStableCheck = name: got: system: sysGot:
    if got != stableVer then "FAIL: ${name}: pkgsStable.path ${got} != nixpkgs-stable ${stableVer}"
    else if got == mainVer then "FAIL: ${name}: pkgsStable is the main nixpkgs (${mainVer})"
    else expect name sysGot system;
  hmOf = host: host.config.home-manager.users.krit;
in
{
  check-stable-input-exists =
    if flake.inputs ? nixpkgs-stable then "ok" else "FAIL: nixpkgs-stable input missing";

  check-no-nixpkgs-unstable-input =
    if flake.inputs ? nixpkgs-unstable then "FAIL: nixpkgs-unstable input still present" else "ok";

  check-stable-older-than-main =
    if lib.versionOlder flake.inputs.nixpkgs-stable.lib.version flake.inputs.nixpkgs.lib.version then "ok"
    else "FAIL: nixpkgs-stable (${flake.inputs.nixpkgs-stable.lib.version}) is not older than nixpkgs (${flake.inputs.nixpkgs.lib.version})";

  check-pkgsstable-nixos-system = guard (
    pkgsStableCheck "pkgsStable (NixOS)" (pkgsStableProbe nixosHost "krit").sysVer "x86_64-linux" (pkgsStableProbe nixosHost "krit").sys
  );

  check-pkgsstable-nixos-home = guard (
    pkgsStableCheck "pkgsStable (NixOS home-manager)" (pkgsStableProbe nixosHost "krit").hmVer "x86_64-linux" (pkgsStableProbe nixosHost "krit").hm
  );

  check-pkgsstable-darwin-system =
    pkgsStableCheck "pkgsStable (Darwin)" (pkgsStableProbe darwinHost "krit").sysVer "aarch64-darwin" (pkgsStableProbe darwinHost "krit").sys;

  check-pkgsstable-darwin-home =
    pkgsStableCheck "pkgsStable (Darwin home-manager)" (pkgsStableProbe darwinHost "krit").hmVer "aarch64-darwin" (pkgsStableProbe darwinHost "krit").hm;

  check-catppuccin-nixos-system = guard (
    expect "catppuccin enable/autoEnable (NixOS system)"
      [ nixosHost.config.catppuccin.enable nixosHost.config.catppuccin.autoEnable ]
      [ true false ]
  );

  check-catppuccin-nixos-home = guard (
    expect "catppuccin enable/autoEnable (NixOS home-manager)"
      [ (hmOf nixosHost).catppuccin.enable (hmOf nixosHost).catppuccin.autoEnable ]
      [ true false ]
  );

  check-catppuccin-darwin-home =
    expect "catppuccin enable/autoEnable (Darwin home-manager)"
      [ (hmOf darwinHost).catppuccin.enable (hmOf darwinHost).catppuccin.autoEnable ]
      [ true false ];

  check-vicinae-font-family = guard (
    expect "vicinae font family"
      vicinaeHm.programs.vicinae.settings.font.normal.family "JetBrainsMono Nerd Font"
  );

  check-vicinae-font-size = guard (
    expect "vicinae font size" vicinaeHm.programs.vicinae.settings.font.normal.size 12
  );

  check-vicinae-stylix-fonts-off = guard (
    expect "stylix vicinae fonts.enable"
      [ (withModules nixosHost [{ myconfig.programs.vicinae.enable = true; }]).config.myconfig.stylix.targets.vicinae.fonts.enable vicinaeHm.stylix.targets.vicinae.fonts.enable ]
      [ false false ]
  );

  check-atuin-ctrl-r-disabled = guard (
    expect "atuin flags" (atuinFor "bash").flags [ "--disable-ctrl-r" ]
  );

  check-atuin-bash-ctrl-o = guard (
    if hasLine "atuin-bind -m emacs '\\C-o' atuin-search-emacs" (atuinFor "bash").bash then "ok"
    else "FAIL: bash initExtra lacks Ctrl-O atuin-search binding"
  );

  check-atuin-zsh-ctrl-o = guard (
    if hasLine "bindkey -M emacs '^o' atuin-search" (atuinFor "zsh").zsh then "ok"
    else "FAIL: zsh initContent lacks Ctrl-O atuin-search binding"
  );

  check-atuin-fish-ctrl-o = guard (
    if hasLine "bind ctrl-o _atuin_search" (atuinFor "fish").fish then "ok"
    else "FAIL: fish interactiveShellInit lacks Ctrl-O atuin-search binding"
  );

  check-atuin-fish-insert-ctrl-o = guard (
    if hasLine "bind -M insert ctrl-o _atuin_search" (atuinFor "fish").fish then "ok"
    else "FAIL: fish interactiveShellInit lacks insert-mode Ctrl-O atuin-search binding"
  );

  check-atuin-disabled-no-bindings = guard (
    let d = atuinWith false;
    in
    if has "atuin-search" (d "bash").bash || has "atuin-search" (d "zsh").zsh || has "atuin-search" (d "fish").fish
    then "FAIL: atuin bindings present while myconfig.programs.atuin.enable = false"
    else "ok"
  );
}
