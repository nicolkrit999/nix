{ delib
, lib
, config
, inputs
, moduleSystem
, ...
}:
let
  commonSecrets = ../sops/krit-common-secrets-sops.yaml;

  mkClaudeMcpSecrets = owner: personal:
    lib.optionalAttrs personal.enable (lib.listToAttrs (map
      (s: {
        name = s.sopsSecret;
        value = { sopsFile = commonSecrets; } // lib.optionalAttrs (owner != null) { inherit owner; };
      })
      personal.mcpSecrets));

  mkShared = user: homeDir: {
    github_fg_pat_token_nix = {
      sopsFile = commonSecrets;
      owner = user;
    };
    github_general_ssh_pub = {
      sopsFile = commonSecrets;
      owner = user;
      path = "${homeDir}/.ssh/id_github.pub";
    };
    github_general_ssh_key = {
      sopsFile = commonSecrets;
      owner = user;
      path = "${homeDir}/.ssh/id_github";
    };
    attic-push-token = {
      sopsFile = commonSecrets;
      owner = user;
    };
    cachix-push-token = {
      sopsFile = commonSecrets;
      owner = user;
    };
  };
in
delib.module {
  name = "krit.commonSopsSecrets";

  options = delib.singleEnableOption false;

  nixos.always.imports = [ inputs.nix-sops.nixosModules.sops ];
  darwin.always.imports = [ inputs.nix-sops.darwinModules.sops ];

  home.always.imports = lib.optionals (moduleSystem == "home") [ inputs.nix-sops.homeManagerModules.sops ];

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user;
    in
    {
      sops.secrets = mkShared user config.users.users.${user}.home // {
        nas_opencloud_user.sopsFile = commonSecrets;
        nas_opencloud_pass.sopsFile = commonSecrets;

        tailscale_key.sopsFile = commonSecrets;

        hevy_api_key = {
          sopsFile = commonSecrets;
          owner = user;
        };
      } // mkClaudeMcpSecrets user myconfig.krit.programs.claude-code-personal;
    };

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user;
      homeDir = config.users.users.${user}.home;
    in
    {
      sops.secrets = mkShared user homeDir // {
        school_ssh_key = {
          sopsFile = commonSecrets;
          owner = user;
          path = "${homeDir}/.ssh/id_school";
        };
        school_ssh_pub = {
          sopsFile = commonSecrets;
          owner = user;
          path = "${homeDir}/.ssh/id_school.pub";
        };
      } // mkClaudeMcpSecrets user myconfig.krit.programs.claude-code-personal;
    };

  home.ifEnabled =
    { myconfig, ... }:
    lib.optionalAttrs (moduleSystem == "nixos")
      {
        programs.fish.interactiveShellInit = lib.mkBefore ''
          if test -r ${config.sops.secrets.hevy_api_key.path}
            set -gx HEVY_API_KEY (cat ${config.sops.secrets.hevy_api_key.path})
          end
        '';
      }
    // lib.optionalAttrs (moduleSystem == "home") {
      sops = {
        defaultSopsFile = commonSecrets;
        age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

        secrets = {
          github_general_ssh_pub.path = "${config.home.homeDirectory}/.ssh/id_github.pub";
          github_general_ssh_key.path = "${config.home.homeDirectory}/.ssh/id_github";
        } // mkClaudeMcpSecrets null myconfig.krit.programs.claude-code-personal;
      };
    };
}
