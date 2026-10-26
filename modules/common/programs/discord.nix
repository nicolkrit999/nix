{ delib
, inputs
, lib
, pkgs
, ...
}:
let
  branchPname = {
    stable = "discord";
    ptb = "discord-ptb";
    canary = "discord-canary";
    development = "discord-development";
  };

  nixpkgsDiscord = pkgs.discord // {
    override = lib.setFunctionArgs
      (args:
        pkgs.discord.override (old: (removeAttrs args [ "branch" ]) // {
          pname = branchPname.${args.branch or "stable"};
          commandLineArgs = lib.concatStringsSep " "
            (lib.filter (s: s != "") [ (old.commandLineArgs or "") (args.commandLineArgs or "") ]);
        }))
      {
        branch = true;
        commandLineArgs = true;
        withVencord = true;
        withEquicord = true;
        withOpenASAR = true;
        vencord = true;
        equicord = true;
      };
  };
in
delib.module {
  name = "programs.discord";
  options = delib.singleEnableOption false;

  home.always.imports = [ inputs.nixcord.homeModules.nixcord ];

  home.ifEnabled.programs.nixcord = {
    enable = true;
    discord.vencord.enable = true;
    discord.package = lib.mkIf pkgs.stdenv.hostPlatform.isLinux nixpkgsDiscord;
  };
}
