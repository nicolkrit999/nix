{ delib
, lib
, inputs
, moduleSystem
, ...
}:
let
  commonSecrets = ../sops/krit-common-secrets-sops.yaml;

  mkClaudeMcpSecrets = user: mcpSecrets:
    lib.listToAttrs (map
      (s: {
        name = s.sopsSecret;
        value = {
          sopsFile = commonSecrets;
          owner = user;
        };
      })
      mcpSecrets);

  mkClaudeMcpSecretsHome = mcpSecrets:
    lib.listToAttrs (map
      (s: {
        name = s.sopsSecret;
        value = {
          sopsFile = commonSecrets;
        };
      })
      mcpSecrets);
in
delib.module {
  name = "krit.commonSopsSecrets";

  options = delib.singleEnableOption false;

  nixos.always.imports = [ inputs.nix-sops.nixosModules.sops ];
  darwin.always.imports = [ inputs.nix-sops.darwinModules.sops ];

  home.always.imports = lib.optionals (moduleSystem == "home") [ inputs.nix-sops.homeManagerModules.sops ];

  # ===========================================================================
  # NixOS - secrets shared across NixOS hosts (/home paths)
  # ===========================================================================
  nixos.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user;
    in
    {
      sops.secrets = {
        github_fg_pat_token_nix = {
          sopsFile = commonSecrets;
          mode = "0444";
        };

        github_general_ssh_pub = {
          sopsFile = commonSecrets;
          owner = user;
          path = "/home/${user}/.ssh/id_github.pub";
        };

        github_general_ssh_key = {
          sopsFile = commonSecrets;
          owner = user;
          path = "/home/${user}/.ssh/id_github";
        };

        nas_ssh_key.sopsFile = commonSecrets;
        nas-krit-credentials.sopsFile = commonSecrets;
        nas_owncloud_url.sopsFile = commonSecrets;
        nas_owncloud_user.sopsFile = commonSecrets;
        nas_owncloud_pass.sopsFile = commonSecrets;

        tailscale_key.sopsFile = commonSecrets;

        hevy_api_key = {
          sopsFile = commonSecrets;
          owner = user;
        };

        # Push tokens - live in the shared common sops file
        attic-push-token = {
          sopsFile = commonSecrets;
          owner = user;
        };
        cachix-push-token = {
          sopsFile = commonSecrets;
          owner = user;
        };

        borg-passphrase = { };
        borg-private-key = { };
      } // mkClaudeMcpSecrets user myconfig.programs.claude-code.mcpSecrets;
    };

  # ===========================================================================
  # Darwin - secrets for the MacBook (/Users paths, static MCP list)
  # ===========================================================================
  darwin.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user;
    in
    {
      sops.secrets = {
        github_fg_pat_token_nix = {
          sopsFile = commonSecrets;
          mode = "0444";
        };
        github_general_ssh_key = {
          sopsFile = commonSecrets;
          owner = user;
          path = "/Users/${user}/.ssh/id_github";
          mode = "0600";
        };
        github_general_ssh_pub = {
          sopsFile = commonSecrets;
          owner = user;
          path = "/Users/${user}/.ssh/id_github.pub";
          mode = "0644";
        };
        school_ssh_key = {
          sopsFile = commonSecrets;
          owner = user;
          path = "/Users/${user}/.ssh/id_school";
          mode = "0600";
        };
        school_ssh_pub = {
          sopsFile = commonSecrets;
          owner = user;
          path = "/Users/${user}/.ssh/id_school.pub";
          mode = "0644";
        };
        openrouter_api_claude_code = {
          sopsFile = commonSecrets;
          owner = user;
        };
        claude_mcp_actual_password = {
          sopsFile = commonSecrets;
          owner = user;
        };
        claude_mcp_actual_sync_id = {
          sopsFile = commonSecrets;
          owner = user;
        };
        claude_mcp_actual_encryption_password = {
          sopsFile = commonSecrets;
          owner = user;
        };
        claude_mcp_context7_api_key = {
          sopsFile = commonSecrets;
          owner = user;
        };
        claude_mcp_openai_api_key = {
          sopsFile = commonSecrets;
          owner = user;
        };
        claude_mcp_milvus_token = {
          sopsFile = commonSecrets;
          owner = user;
        };
        claude_mcp_github_token = {
          sopsFile = commonSecrets;
          owner = user;
        };
        claude_mcp_portainer_token = {
          sopsFile = commonSecrets;
          owner = user;
        };
        claude_mcp_sparkyfitness_api_key = {
          sopsFile = commonSecrets;
          owner = user;
        };
        /*
        claude_mcp_kagi_api_key = {
          sopsFile = commonSecrets;
          owner = user;
        };
        */
        tailscale_key = {
          sopsFile = commonSecrets;
          owner = user;
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
    };

  home.ifEnabled =
    { myconfig, ... }:
    if moduleSystem == "home" then
      let
        user = myconfig.constants.user;
        homeDir = "/home/${user}";
      in
      {
        sops.defaultSopsFile = commonSecrets;
        sops.age.keyFile = "${homeDir}/.config/sops/age/keys.txt";

        sops.secrets = {
          github_fg_pat_token_nix = { };
          github_general_ssh_pub = {
            path = "${homeDir}/.ssh/id_github.pub";
          };
          github_general_ssh_key = {
            path = "${homeDir}/.ssh/id_github";
          };
          tailscale_key = { };
        } // mkClaudeMcpSecretsHome myconfig.programs.claude-code.mcpSecrets;
      }
    else
      { };
}
