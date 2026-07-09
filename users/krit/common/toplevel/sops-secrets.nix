{ delib
, lib
, inputs
, moduleSystem
, ...
}:
let
  commonSecrets = ../sops/krit-common-secrets-sops.yaml;

  # Per-host secrets file for the home-manager-standalone NAS host. Not used as
  # `sops.defaultSopsFile` below (that stays `commonSecrets` - deliberately
  # unchanged, see comment in the home.ifEnabled block), but available for any
  # future NAS-only secret: add it under `sops.secrets` there with an explicit
  # `sopsFile = nicolNasSecrets;` override, the same way the nixos.ifEnabled
  # block above overrides individual secrets with `sopsFile = commonSecrets;`
  # (just the inverse - host file is the exception here, not the default).

  # sops.secrets attrs generated from programs.claude-code.mcpSecrets (NixOS/Darwin system-level)
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

  # Same, but for sops-nix's home-manager module: its secretType has no
  # `owner` option (single-user context, nothing to chown to) - passing one
  # would be a hard eval error ("no option named `owner`"), not a no-op.
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

  # Ensure the sops option set exists wherever this module is loaded.
  nixos.always.imports = [ inputs.nix-sops.nixosModules.sops ];
  darwin.always.imports = [ inputs.nix-sops.darwinModules.sops ];

  # Standalone home-manager builds (e.g. nicol-nas) have no system-level sops -
  # import sops-nix's own home-manager module instead. Guarded to
  # moduleSystem == "home" only, so NixOS/Darwin hosts (which already get
  # secrets from the system-level sops above) are never double-managed.
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

        # rclone_google_drive_conf / rclone_onedrive_personal_conf / rclone_pcloud_conf
        # are declared solely by their consuming service modules under
        # users/krit/nixos/services/cloud/ - not duplicated here.

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

        # Borg backup - identical on both NixOS hosts, but stored in each host's
        # OWN default sops file, so no sopsFile override (resolves per host).
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

  # ===========================================================================
  # Home-manager-standalone hosts (moduleSystem == "home", e.g. nicol-nas) -
  # secrets via sops-nix's home-manager module. Secret `path` here resolves to
  # sops-nix's XDG-runtime default symlink dir, NOT /run/secrets - anything
  # that hardcodes /run/secrets/<name> (e.g. claude-code-wrappers.nix) will
  # NOT find these; that's the known gap, not something patched around here.
  # ===========================================================================
  # NOTE on the guard shape: `moduleSystem` is a plain flake-level arg (not a
  # config/myconfig attribute), so testing it is safe from the infinite-
  # recursion trap that `lib.optionalAttrs (myconfig.foo.enable) {...}` falls
  # into. But it must be a plain `if/then/else`, NOT `lib.mkIf`: denix nests
  # this same `home.ifEnabled` body inside `home-manager.users.<user>` for
  # NixOS/Darwin builds too (see apply.home in denix's lib/configurations),
  # and on those builds the sops-nix home-manager module is never imported
  # (home.always.imports above is itself gated the same way). `lib.mkIf`
  # keeps the `sops.*` attribute paths structurally present in the merged
  # config even when its condition is false, which the module system checks
  # against declared options regardless of laziness -> "option does not
  # exist" on NixOS/Darwin. A plain `if` makes the branch not taken evaluate
  # to `{ }`, so `sops.*` is structurally absent there instead of just falsy.
  # See feedback_delib_home_ifenable_patterns memory for the same failure
  # mode with stylix.targets.*.
  home.ifEnabled =
    { myconfig, ... }:
    if moduleSystem == "home" then
      let
        user = myconfig.constants.user;
        homeDir = "/home/${user}";
      in
      {
        # Deliberately left as commonSecrets, not nicolNasSecrets - this is
        # already working on the NAS and must not be disturbed. To add a
        # NAS-only secret later, add an entry below with an explicit
        # `sopsFile = nicolNasSecrets;` override (see hosts/Nicol-NAS/
        # Nicol-NAS-secrets-sops.yaml, created empty via the matching
        # .sops.yaml creation_rule) - no other module surgery needed.
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
