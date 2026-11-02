{ delib
, lib
, config
, inputs
, moduleSystem
, pkgs
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

  cfImageSecretNames = [ "cf_account_id" "cf_api_token" ];

  mkCfImageSecrets = owner: personal:
    lib.optionalAttrs personal.enable (lib.genAttrs cfImageSecretNames (_:
      { sopsFile = commonSecrets; } // lib.optionalAttrs (owner != null) { inherit owner; }));

  # personal = false: nothing is placed in or owned by the user; the tokens only root needs stay root-owned.
  mkShared = user: homeDir: personal:
    let
      tokenOwner = if personal then user else "root";
    in
    {
      github_fg_pat_token_nix = {
        sopsFile = commonSecrets;
        owner = tokenOwner;
      };
      attic-push-token = {
        sopsFile = commonSecrets;
        owner = tokenOwner;
      };
      cachix-push-token = {
        sopsFile = commonSecrets;
        owner = tokenOwner;
      };
    }
    // lib.optionalAttrs personal {
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
    };
in
delib.module {
  name = "krit.commonSopsSecrets";

  options = with delib; moduleOptions {
    enable = boolOption false;
    # false: the ssh identity and personal API keys are not declared and the shared tokens belong to root
    personalSecrets = boolOption true;
  };

  nixos.always.imports = [ inputs.nix-sops.nixosModules.sops ];
  darwin.always.imports = [ inputs.nix-sops.darwinModules.sops ];

  home.always.imports = lib.optionals (moduleSystem == "home") [ inputs.nix-sops.homeManagerModules.sops ];

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      user = myconfig.constants.user;
    in
    {
      sops.secrets = mkShared user config.users.users.${user}.home cfg.personalSecrets // {
        nas_opencloud_user.sopsFile = commonSecrets;
        nas_opencloud_pass.sopsFile = commonSecrets;

        tailscale_key.sopsFile = commonSecrets;
      } // lib.optionalAttrs cfg.personalSecrets {
        hevy_api_key = {
          sopsFile = commonSecrets;
          owner = user;
        };
      } // mkClaudeMcpSecrets user myconfig.krit.programs.claude-code-personal
        // mkCfImageSecrets user myconfig.krit.programs.claude-code-personal;
    };

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user;
      homeDir = config.users.users.${user}.home;
    in
    {
      sops.secrets = mkShared user homeDir true // {
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
      } // mkClaudeMcpSecrets user myconfig.krit.programs.claude-code-personal
        // mkCfImageSecrets user myconfig.krit.programs.claude-code-personal;
    };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    lib.mkMerge [
      (lib.mkIf myconfig.krit.programs.claude-code-personal.enable {
        home.packages = lib.optionals
          (moduleSystem == "home" || !myconfig.krit.programs.claude-code-wrappers.enable)
          [ (lib.lowPrio pkgs.python3) ];
        home.sessionVariables = {
          CF_ACCOUNT_ID_FILE = config.sops.secrets.cf_account_id.path;
          CF_API_TOKEN_FILE = config.sops.secrets.cf_api_token.path;
        };
      })
      (lib.optionalAttrs (moduleSystem == "nixos" && cfg.personalSecrets)
        {
          programs.fish.interactiveShellInit = lib.mkBefore ''
            if test -r ${config.sops.secrets.hevy_api_key.path}
              set -gx HEVY_API_KEY (cat ${config.sops.secrets.hevy_api_key.path})
            end
          '';
        })
      (lib.optionalAttrs (moduleSystem == "home") {
        sops = {
          defaultSopsFile = commonSecrets;
          age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

          secrets = {
            github_general_ssh_pub.path = "${config.home.homeDirectory}/.ssh/id_github.pub";
            github_general_ssh_key.path = "${config.home.homeDirectory}/.ssh/id_github";
          } // mkClaudeMcpSecrets null myconfig.krit.programs.claude-code-personal
          // mkCfImageSecrets null myconfig.krit.programs.claude-code-personal;
        };
      })
    ];
}
