# Opinionated: common SOPS secrets shared across krit's hosts.
#
# Replaces the old manually-imported templates/krit/sops/common-secrets.nix.
# Because the NixOS and Darwin hosts use different home roots (/home vs /Users)
# and a different MCP-secret strategy (dynamic vs static), the secret set is
# expressed once per platform via nixos.ifEnabled / darwin.ifEnabled.
#
# Enable per host with `krit.commonSopsSecrets.enable = true;` in its default.nix.
# Each host still owns its host-specific secrets (e.g. krit-local-password)
# in its own system.nix, plus its sops defaultSopsFile / age config.
#
# The sops module is imported here in the `always` blocks so the `sops` option
# is guaranteed to exist wherever this module is loaded — a host's own
# `imports` of the sops module does not reliably propagate to sibling denix
# modules during evaluation.
{ delib
, lib
, inputs
, ...
}:
let
  commonSecrets = ../sops/krit-common-secrets-sops.yaml;

  # sops.secrets attrs generated from programs.claude-code.mcpSecrets (NixOS)
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
in
delib.module {
  name = "krit.commonSopsSecrets";

  options = delib.singleEnableOption false;

  # Ensure the sops option set exists wherever this module is loaded.
  nixos.always.imports = [ inputs.nix-sops.nixosModules.sops ];
  darwin.always.imports = [ inputs.nix-sops.darwinModules.sops ];

  # ===========================================================================
  # NixOS — secrets shared across NixOS hosts (/home paths)
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

        # Push tokens — live in the shared common sops file
        attic-push-token = {
          sopsFile = commonSecrets;
          owner = user;
        };
        cachix-push-token = {
          sopsFile = commonSecrets;
          owner = user;
        };

        # Borg backup — identical on both NixOS hosts, but stored in each host's
        # OWN default sops file, so no sopsFile override (resolves per host).
        borg-passphrase = { };
        borg-private-key = { };
      } // mkClaudeMcpSecrets user myconfig.programs.claude-code.mcpSecrets;
    };

  # ===========================================================================
  # Darwin — secrets for the MacBook (/Users paths, static MCP list)
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
}
