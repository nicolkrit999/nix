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
        })
        { home-manager.users.${hmUser} = { pkgsStable, ... }: { home.file."probe-hm".text = pkgsStable.stdenv.hostPlatform.system; }; }
      ];
    in
    {
      sys = x.config.environment.etc."probe-sys".text;
      hm = x.config.home-manager.users.${hmUser}.home.file."probe-hm".text;
    };

  atuinFor = shell:
    let
      x = withModules nixosHost [
        ({ lib, ... }: {
          myconfig.programs.atuin.enable = true;
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
    expect "pkgsStable system (NixOS)" (pkgsStableProbe nixosHost "krit").sys "x86_64-linux"
  );

  check-pkgsstable-nixos-home = guard (
    expect "pkgsStable system (NixOS home-manager)" (pkgsStableProbe nixosHost "krit").hm "x86_64-linux"
  );

  check-pkgsstable-darwin-system =
    expect "pkgsStable system (Darwin)" (pkgsStableProbe darwinHost "krit").sys "aarch64-darwin";

  check-pkgsstable-darwin-home =
    expect "pkgsStable system (Darwin home-manager)" (pkgsStableProbe darwinHost "krit").hm "aarch64-darwin";

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
      (hmOf nixosHost).programs.vicinae.settings.font.normal.family "JetBrainsMono Nerd Font"
  );

  check-vicinae-font-size = guard (
    expect "vicinae font size" (hmOf nixosHost).programs.vicinae.settings.font.normal.size 12
  );

  check-vicinae-stylix-fonts-off = guard (
    expect "stylix vicinae fonts.enable"
      [ nixosHost.config.myconfig.stylix.targets.vicinae.fonts.enable (hmOf nixosHost).stylix.targets.vicinae.fonts.enable ]
      [ false false ]
  );

  check-atuin-ctrl-r-disabled = guard (
    expect "atuin flags" (atuinFor "bash").flags [ "--disable-ctrl-r" ]
  );

  check-atuin-bash-ctrl-o = guard (
    if has "atuin-bind -m emacs '\\C-o' atuin-search-emacs" (atuinFor "bash").bash then "ok"
    else "FAIL: bash initExtra lacks Ctrl-O atuin-search binding"
  );

  check-atuin-zsh-ctrl-o = guard (
    if has "bindkey -M emacs '^o' atuin-search" (atuinFor "zsh").zsh then "ok"
    else "FAIL: zsh initContent lacks Ctrl-O atuin-search binding"
  );

  check-atuin-fish-ctrl-o = guard (
    if has "bind ctrl-o _atuin_search" (atuinFor "fish").fish then "ok"
    else "FAIL: fish interactiveShellInit lacks Ctrl-O atuin-search binding"
  );
}
