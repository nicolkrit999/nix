# Common SOPS secrets shared across all hosts with sops enabled
# Import this in host system.nix and merge into sops.secrets
#
# Usage in system.nix (inside an inline import where lib is available):
#   sops.secrets = {
#     # host-specific secrets
#   } // (import ../../templates/krit/sops/common-secrets.nix {
#     inherit lib;
#     user = myUserName;
#     claudeCodeMcpSecrets = config.myconfig.programs.claude-code.mcpSecrets;
#   });
{ lib, user, claudeCodeMcpSecrets ? [ ] }:
let
  commonSecrets = ../../../users/krit/common/sops/krit-common-secrets-sops.yaml;

  # Base common secrets
  baseSecrets = {
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
  };

  # Claude-code MCP secrets (dynamically generated from mcpSecrets list)
  claudeCodeSecrets = lib.listToAttrs (
    map
      (s: {
        name = s.sopsSecret;
        value = {
          sopsFile = commonSecrets;
          owner = user;
        };
      })
      claudeCodeMcpSecrets
  );
in
baseSecrets // claudeCodeSecrets
