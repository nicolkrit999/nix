{ delib, pkgs, lib, ... }:
delib.module {
  name = "krit.services.nixos-desktop.claude-code-wrappers";

  nixos.always =
    { myconfig, ... }:
    {
      environment.systemPackages = lib.optionals myconfig.programs.claude-code.enable [
        # cai — passthrough, launches claude with whatever env is present
        (pkgs.writeShellScriptBin "cai" ''
          exec ${pkgs.claude-code}/bin/claude "$@"
        '')

        # cai-sub — forces Pro subscription by stripping all OpenRouter env vars
        (pkgs.writeShellScriptBin "cai-sub" ''
          exec env \
            -u ANTHROPIC_BASE_URL \
            -u ANTHROPIC_AUTH_TOKEN \
            -u ANTHROPIC_MODEL \
            -u ANTHROPIC_API_KEY \
            -u OPENROUTER_API_KEY \
            ${pkgs.claude-code}/bin/claude "$@"
        '')

        # cai-openrouter — routes through OpenRouter using SOPS-managed API key.
        # Fails hard if the secret is missing — no fallback to Pro/OAuth ever.
        # Uses ANTHROPIC_AUTH_TOKEN (→ Authorization: Bearer) which OpenRouter requires.
        # Temporarily strips oauthAccount from ~/.claude.json so the login session
        # does not override ANTHROPIC_AUTH_TOKEN; restores it after claude exits.
        (pkgs.writeShellScriptBin "cai-openrouter" ''
          if [ ! -f /run/secrets/openrouter_api_claude_code ]; then
            echo "Error: /run/secrets/openrouter_api_claude_code not found." >&2
            echo "Run 'darwin-rebuild switch' or check your SOPS config." >&2
            exit 1
          fi

          CLAUDE_JSON="$HOME/.claude.json"

          if [ -f "$CLAUDE_JSON" ] && ${pkgs.jq}/bin/jq -e '.oauthAccount != null' "$CLAUDE_JSON" >/dev/null 2>&1; then
            OAUTH_VALUE=$(${pkgs.jq}/bin/jq -c '.oauthAccount' "$CLAUDE_JSON")
            TMPJSON=$(mktemp)
            ${pkgs.jq}/bin/jq 'del(.oauthAccount)' "$CLAUDE_JSON" > "$TMPJSON" && mv "$TMPJSON" "$CLAUDE_JSON"
            restore_oauth() {
              ${pkgs.jq}/bin/jq --argjson v "$OAUTH_VALUE" '.oauthAccount = $v' "$CLAUDE_JSON" \
                > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
            }
            trap restore_oauth EXIT
          fi

          env \
            ANTHROPIC_API_KEY="" \
            ANTHROPIC_BASE_URL="https://openrouter.ai/api" \
            ANTHROPIC_AUTH_TOKEN="$(cat /run/secrets/openrouter_api_claude_code)" \
            ${pkgs.claude-code}/bin/claude "$@"
        '')
      ];
    };
}
