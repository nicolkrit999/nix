{
  delib,
  pkgs,
  inputs,
  ...
}:
delib.module {
  name = "programs.claude-code";
  options = delib.singleEnableOption false;

  darwin.always =
    { ... }:
    {
      nixpkgs.overlays = [
        inputs.claude-code.overlays.default
      ];
    };

  darwin.ifEnabled =
    { myconfig, ... }:
    {
      environment.systemPackages = [
        pkgs.claude-code
      ];
    };

  home.ifEnabled =
    { myconfig, ... }:
    {
      programs.fish.shellAbbrs = {
        caitempplugins = "npx claude-code-templates@latest --plugins";
        caitemphealt = "npx claude-code-templates@latest --health-check";
        caitempchat = "npx claude-code-templates@latest --chats";
        caitempanalytics = "npx claude-code-templates@latest --analytics";
        cai-openrouter-geminipro = "cai-openrouter --model google/gemini-3.1-pro-preview[1m]";
        cai-openrouter-geminiflash = "cai-openrouter --model google/gemini-3.1-flash-lite-preview[1m]";
        cai-openrouter-gptpro = "cai-openrouter --model openai/gpt-5.4-pro[1m]";
        cai-openrouter-gptmini = "cai-openrouter --model openai/gpt-5.4-mini[1m]"; # In reality support 400k but it does not recognize "k" nor "m" with decimals
        cai-openrouter-opus = "cai-openrouter --model anthropic/claude-opus-4.6[1m]";
        cai-openrouter-sonnet = "cai-openrouter --model anthropic/claude-sonnet-4.6[1m]";
        cai-openrouter-maverick = "cai-openrouter --model meta-llama/llama-4-maverick[1m]";
        cai-openrouter-scout = "cai-openrouter --model meta-llama/llama-4-scout[1m]";
        cai-openrouter-glmturbo = "cai-openrouter --model z-ai/glm-5-turbo";
        cai-openrouter-grokbeta = "cai-openrouter --model x-ai/grok-4.20-beta[1m]";
        cai-openrouter-grokmulti = "cai-openrouter --model x-ai/grok-4.20-multi-agent-beta[1m]"; # In reality support 2M but it does not alllow anything more than 1m
        cai-openrouter-free-step = "cai-openrouter --model stepfun/step-3.5-flash:free";
        cai-openrouter-free-hunter = "cai-openrouter --model openrouter/hunter-alpha[1m]";
        cai-openrouter-mistralsmall = "cai-openrouter --model mistralai/mistral-small-2603";
        cai-openrouter-kimi = "cai-openrouter --model moonshotai/kimi-k2.5";
        cai-openrouter-qwen = "cai-openrouter --model qwen/qwen3.5-397b-a17b";
        cai-openrouter-minimax = "cai-openrouter --model minimax/minimax-m2.5";
      };

      programs.zsh.shellAliases = {
        caitempplugins = "npx claude-code-templates@latest --plugins";
        caitemphealt = "npx claude-code-templates@latest --health-check";
        caitempchat = "npx claude-code-templates@latest --chats";
        caitempanalytics = "npx claude-code-templates@latest --analytics";
        cai-openrouter-geminipro = "cai-openrouter --model google/gemini-3.1-pro-preview[1m]";
        cai-openrouter-geminiflash = "cai-openrouter --model google/gemini-3.1-flash-lite-preview[1m]";
        cai-openrouter-gptpro = "cai-openrouter --model openai/gpt-5.4-pro[1m]";
        cai-openrouter-gptmini = "cai-openrouter --model openai/gpt-5.4-mini[1m]"; # In reality support 400k but it does not recognize "k" nor "m" with decimals
        cai-openrouter-opus = "cai-openrouter --model anthropic/claude-opus-4.6[1m]";
        cai-openrouter-sonnet = "cai-openrouter --model anthropic/claude-sonnet-4.6[1m]";
        cai-openrouter-maverick = "cai-openrouter --model meta-llama/llama-4-maverick[1m]";
        cai-openrouter-scout = "cai-openrouter --model meta-llama/llama-4-scout[1m]";
        cai-openrouter-glmturbo = "cai-openrouter --model z-ai/glm-5-turbo";
        cai-openrouter-grokbeta = "cai-openrouter --model x-ai/grok-4.20-beta[1m]";
        cai-openrouter-grokmulti = "cai-openrouter --model x-ai/grok-4.20-multi-agent-beta[1m]"; # In reality support 2M but it does not alllow anything more than 1m
        cai-openrouter-free-step = "cai-openrouter --model stepfun/step-3.5-flash:free";
        cai-openrouter-free-hunter = "cai-openrouter --model openrouter/hunter-alpha[1m]";
        cai-openrouter-mistralsmall = "cai-openrouter --model mistralai/mistral-small-2603";
        cai-openrouter-kimi = "cai-openrouter --model moonshotai/kimi-k2.5";
        cai-openrouter-qwen = "cai-openrouter --model qwen/qwen3.5-397b-a17b";
        cai-openrouter-minimax = "cai-openrouter --model minimax/minimax-m2.5";
      };

      home.activation.patchClaudeJsonSecrets =
        inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
          ''
            _read_secret() {
              if [ -f "$1" ]; then
                cat "$1" 2>/dev/null || true
              fi
            }

            CLAUDE_JSON="$HOME/.claude.json"
            if [ -f "$CLAUDE_JSON" ]; then
              ${pkgs.jq}/bin/jq \
                --arg actual_pw "$(_read_secret /run/secrets/claude_mcp_actual_password)" \
                --arg actual_sync "$(_read_secret /run/secrets/claude_mcp_actual_sync_id)" \
                --arg actual_enc "$(_read_secret /run/secrets/claude_mcp_actual_encryption_password)" \
                --arg ctx7 "$(_read_secret /run/secrets/claude_mcp_context7_api_key)" \
                --arg openai "$(_read_secret /run/secrets/claude_mcp_openai_api_key)" \
                --arg milvus "$(_read_secret /run/secrets/claude_mcp_milvus_token)" \
                --arg ghtoken "$(_read_secret /run/secrets/claude_mcp_github_token)" \
                '
                (if ($actual_pw != "") and (.mcpServers["budget-principale"]? != null) then .mcpServers["budget-principale"].env.ACTUAL_PASSWORD = $actual_pw else . end) |
                (if ($actual_sync != "") and (.mcpServers["budget-principale"]? != null) then .mcpServers["budget-principale"].env.ACTUAL_BUDGET_SYNC_ID = $actual_sync else . end) |
                (if ($actual_enc != "") and (.mcpServers["budget-principale"]? != null) then .mcpServers["budget-principale"].env.ACTUAL_BUDGET_ENCRYPTION_PASSWORD = $actual_enc else . end) |
                (if ($ctx7 != "") and (.mcpServers["context7"]? != null) then .mcpServers["context7"].args[-1] = $ctx7 else . end) |
                (if ($openai != "") and (.mcpServers["claude-context"]? != null) then .mcpServers["claude-context"].env.OPENAI_API_KEY = $openai else . end) |
                (if ($milvus != "") and (.mcpServers["claude-context"]? != null) then .mcpServers["claude-context"].env.MILVUS_TOKEN = $milvus else . end) |
                (if ($ghtoken != "") and (.mcpServers["github"]? != null) then .mcpServers["github"].headers.Authorization = ("Bearer " + $ghtoken) else . end)
                ' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
            fi
          '';
    };
}
