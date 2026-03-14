{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.claude-code";
  options = delib.singleEnableOption false;

  nixos.always = {
    imports = [ inputs.claude-cowork-service.nixosModules.default ];
  };

  nixos.ifEnabled = {
    services.claude-cowork.enable = true;
    nixpkgs.overlays = [ inputs.claude-code.overlays.default ];

    environment.systemPackages = [ pkgs.claude-code ];

    environment.shellAliases = {
      cai = "claude";
      caitempplugins = "npx claude-code-templates@latest --plugins";
      caitemphealt = "npx claude-code-templates@latest --health-check";
      caitempchat = "npx claude-code-templates@latest --chats";
      caitempanalytics = "npx claude-code-templates@latest --analytics";
    };
  };
}
