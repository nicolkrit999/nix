{ delib, inputs, pkgs, lib, moduleSystem, ... }:
let
  overlays = [ inputs.claude-code.overlays.default ];
  claudeCodeTools = [
    pkgs.bun
    pkgs.gh
    pkgs.nodejs_latest
    pkgs.rtk
  ];
  sharedIfEnabled = {
    environment.systemPackages = [ pkgs.claude-code ] ++ claudeCodeTools;
  };
in
delib.module {
  name = "programs.claude-code";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
    cowork = delib.boolOption false;
    extraEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Static environment variables exported by the `claude` wrapper of home-only builds; with none set, plain pkgs.claude-code is installed.";
    };
    extraPackages = delib.listOfOption lib.types.package [ ];
    extraGitIgnores = delib.listOfOption lib.types.str [ ];
    extraShellAliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Aliases (fish abbreviations for fish) added to the shell selected by myconfig.constants.shell.";
    };
  };

  darwin.always.nixpkgs.overlays = overlays;

  darwin.ifEnabled = sharedIfEnabled;

  nixos.always = {
    imports = [ inputs.claude-cowork-service.nixosModules.default ];
    nixpkgs.overlays = overlays;
  };

  nixos.ifEnabled = { cfg, ... }: sharedIfEnabled // {
    services.claude-cowork.enable = cfg.cowork;
  };

  home.always = lib.optionalAttrs (moduleSystem == "home") {
    nixpkgs.overlays = overlays;
  };

  home.ifEnabled = { cfg, myconfig, ... }:
    let
      exports = lib.mapAttrsToList
        (name: value: "export ${name}=${lib.escapeShellArg value}")
        cfg.extraEnv;

      claudeHomeWrapper = pkgs.writeShellScriptBin "claude" ''
        ${lib.concatStringsSep "\n" exports}
        exec ${pkgs.claude-code}/bin/claude "$@"
      '';

      claudeHome = if cfg.extraEnv == { } then pkgs.claude-code else claudeHomeWrapper;
    in
    {
      home.sessionVariables.CLAUDE_BINARY = "${pkgs.claude-code}/bin/.claude-unwrapped";

      home.packages = lib.optionals (moduleSystem == "home") ([ claudeHome ] ++ claudeCodeTools ++ cfg.extraPackages);

      programs = {
        git.ignores = cfg.extraGitIgnores;
        fish.shellAbbrs = lib.mkIf (myconfig.constants.shell == "fish") cfg.extraShellAliases;
        zsh.shellAliases = lib.mkIf (myconfig.constants.shell == "zsh") cfg.extraShellAliases;
        bash.shellAliases = lib.mkIf (myconfig.constants.shell == "bash") cfg.extraShellAliases;
      };
    };
}
