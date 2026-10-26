{ delib
, lib
, moduleSystem
, pkgs
, ...
}:
let
  openrouterAliases = {
    cai-openrouter-geminipro = "cai-openrouter --model google/gemini-3.1-pro-preview[1m]";
    cai-openrouter-geminiflash = "cai-openrouter --model google/gemini-3.1-flash-lite-preview[1m]";
    cai-openrouter-gptpro = "cai-openrouter --model openai/gpt-5.5-pro[1m]";
    cai-openrouter-gptmini = "cai-openrouter --model openai/gpt-5.5-mini[1m]"; # In reality support 400k but it does not recognize "k" nor "m" with decimals
    cai-openrouter-opus = "cai-openrouter --model anthropic/claude-opus-4.7[1m]";
    cai-openrouter-sonnet = "cai-openrouter --model anthropic/claude-sonnet-4.7[1m]";
    cai-openrouter-maverick = "cai-openrouter --model meta-llama/llama-4-maverick[1m]";
    cai-openrouter-scout = "cai-openrouter --model meta-llama/llama-4-scout[1m]";
    cai-openrouter-glmturbo = "cai-openrouter --model z-ai/glm-5-turbo";
    cai-openrouter-grokbeta = "cai-openrouter --model x-ai/grok-4.20-beta[1m]";
    cai-openrouter-grokmulti = "cai-openrouter --model x-ai/grok-4.20-multi-agent-beta[1m]"; # In reality support 2M but it does not allow anything more than 1m
    cai-openrouter-free-step = "cai-openrouter --model stepfun/step-3.5-flash:free";
    cai-openrouter-free-hunter = "cai-openrouter --model openrouter/hunter-alpha[1m]";
    cai-openrouter-mistralsmall = "cai-openrouter --model mistralai/mistral-small-2603";
    cai-openrouter-kimi = "cai-openrouter --model moonshotai/kimi-k2.5";
    cai-openrouter-qwen = "cai-openrouter --model qwen/qwen3.5-397b-a17b";
    cai-openrouter-minimax = "cai-openrouter --model minimax/minimax-m2.5";
  };

  claude = "${pkgs.claude-code}/bin/claude";

  stripEnv = lib.concatMapStringsSep " " (v: "-u ${v}") [
    "ANTHROPIC_BASE_URL"
    "ANTHROPIC_AUTH_TOKEN"
    "ANTHROPIC_MODEL"
    "ANTHROPIC_API_KEY"
    "OPENROUTER_API_KEY"
  ];

  caiScript = pkgs.writeShellScriptBin "cai" ''
    # cai is local-only; cloud sessions go through ccai.
    for a in "$@"; do
      case "$a" in
        --cloud|--cloud=*)
          echo "cai: --cloud is not allowed here, use ccai instead." >&2
          exit 1
          ;;
      esac
    done

    CLAUDE_JSON="$HOME/.claude.json"
    TARGET="$(readlink -f "$CLAUDE_JSON" 2>/dev/null || echo "$CLAUDE_JSON")"
    if [ -f "$TARGET" ]; then
      # Write through the resolved path so the dotfiles symlink is preserved.
      TMP="$TARGET.cai-policy.tmp"
      if ${pkgs.jq}/bin/jq --arg cwd "$PWD" '
        (.claudeAiMcpEverConnected // []) as $conns
        | .disabledMcpServers = $conns
        | .projects //= {}
        | .projects[$cwd] //= {}
        | .projects |= with_entries(
            .value.disabledMcpServers =
              (((.value.disabledMcpServers // []) + $conns) | unique)
          )
      ' "$TARGET" > "$TMP" 2>/dev/null; then
        mv "$TMP" "$TARGET"
      else
        rm -f "$TMP"
      fi
    fi
    exec ${claude} "$@"
  '';

  caiSubScript = pkgs.writeShellScriptBin "cai-sub" ''
    exec env ${stripEnv} ${claude} "$@"
  '';

  # Cloud session on the normal Anthropic route. Cloud sessions run on
  # Anthropic's side, so any OpenRouter/custom-endpoint env is stripped.
  # `claude --cloud` needs a task description: if none was given, ask for it
  # and pass it straight through instead of failing.
  ccaiScript = pkgs.writeShellScriptBin "ccai" ''
    # Only --environment is known to take a value; any other value-taking flag must be written --flag=value.
    flags=()
    desc=""
    takes_value=0
    for a in "$@"; do
      if [ "$takes_value" = 1 ]; then
        flags+=("$a")
        takes_value=0
        continue
      fi
      case "$a" in
        --environment) flags+=("$a"); takes_value=1 ;;
        -*) flags+=("$a") ;;
        *) desc="$desc''${desc:+ }$a" ;;
      esac
    done

    if [ -z "$desc" ]; then
      if [ ! -t 0 ]; then
        echo "ccai: a task description is required (usage: ccai \"task\" [flags])." >&2
        exit 1
      fi
      while [ -z "$desc" ]; do
        printf 'Cloud task description: ' >&2
        IFS= read -r desc || exit 1
      done
    fi

    exec env ${stripEnv} ${claude} --cloud "$desc" "''${flags[@]}"
  '';

  caiOpenrouterScript = pkgs.writeShellScriptBin "cai-openrouter" ''
    if [ ! -f /run/secrets/openrouter_api_claude_code ]; then
      echo "Error: /run/secrets/openrouter_api_claude_code not found." >&2
      echo "Rebuild the system or check your SOPS config." >&2
      exit 1
    fi

    CLAUDE_JSON="$HOME/.claude.json"
    TARGET="$(readlink -f "$CLAUDE_JSON" 2>/dev/null || echo "$CLAUDE_JSON")"
    TMP="$TARGET.cai-openrouter.tmp"

    if [ -f "$TARGET" ] && ${pkgs.jq}/bin/jq -e '.oauthAccount != null' "$TARGET" >/dev/null 2>&1; then
      OAUTH_VALUE=$(${pkgs.jq}/bin/jq -c '.oauthAccount' "$TARGET")
      ${pkgs.jq}/bin/jq 'del(.oauthAccount)' "$TARGET" > "$TMP" && mv "$TMP" "$TARGET" || rm -f "$TMP"
      restore_oauth() {
        ${pkgs.jq}/bin/jq --argjson v "$OAUTH_VALUE" '.oauthAccount = $v' "$TARGET" \
          > "$TMP" && mv "$TMP" "$TARGET" || rm -f "$TMP"
      }
      trap restore_oauth EXIT
    fi

    ANTHROPIC_API_KEY="" \
    ANTHROPIC_BASE_URL="https://openrouter.ai/api" \
    ANTHROPIC_AUTH_TOKEN="$(< /run/secrets/openrouter_api_claude_code)" \
    ${claude} "$@"
  '';

  pythonWithPackages = pkgs.python313.withPackages (
    ps: with ps; [
      bibtexparser # citation-management - BibTeX parsing
      biopython # citation-management - PubMed access
      litellm # perplexity-search, generate-image, infographics
      markitdown # markitdown skill - file-to-markdown
      matplotlib # matplotlib skill
      networkx # networkx skill
      openpyxl # xlsx creation/editing
      pandas # xlsx, data analysis
      pdfplumber # pdf skill - text/table extraction
      pillow # pptx thumbnail grids, image handling
      pypdf # pdf skill - merge/split/metadata
      python-docx # docx skill - creation/editing
      python-pptx # pptx skill - presentation creation
      reportlab # pdf skill - create PDFs
      requests # citation-management, literature-review
      scholarly # citation-management - Google Scholar
    ]
    ++ markitdown.optional-dependencies.all # docx/xlsx/xls/pdf/pptx/audio/youtube/outlook converters
    ++ litellm.optional-dependencies.proxy # litellm CLI and proxy server (rich, typer, websockets)
  );

  commonCliTools = [
    pkgs.octave # Matlab skill - numerical computing, plotting, data analysis
    pkgs.pandoc # docx/literature-review - text extraction and PDF generation
    pkgs.poppler-utils # pdf/pptx/docx - pdftoppm, pdftotext, pdfimages
    pkgs.tesseract # pdf - OCR for scanned documents
    pkgs.uv # fast Python package installer (fallback for non-nix envs)
  ];

  # Claude Code companion CLIs installed through the generic programs.npm
  # module; only declared while this module is enabled, so a host without the
  # krit claude setup keeps its own programs.npm list free of them.
  npmPackages = [
    "claude-token-counter" # Token usage counter for claude code
    "claudefm" # terminal music player
    "ui-ux-pro-max-cli" # UI/UX design skill installer (uipro)
  ];

  # Not published to npm (and a git install lacks the built dist/), so it is
  # built from a pinned rev. Hooks in the Claude settings call `agent-floor hook claude`.
  agentFloor = pkgs.buildNpmPackage {
    pname = "agent-floor";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "develop212";
      repo = "agent-floor";
      rev = "c5422bbea7d6d7c814dd8ef60737ccaebef8e6e8";
      hash = "sha256-risyQl67TFFbkzTl6n8RP3SyNS9CkwQxjr+h3LwA/o0=";
    };
    npmDepsHash = "sha256-wznN+Vr/HWL4TTQJO34VMAUYRG3SAELVyABF1YwBXwU=";
    meta.mainProgram = "agent-floor";
  };

  sharedPackages = [
    agentFloor
    caiOpenrouterScript
    caiScript
    caiSubScript
    ccaiScript
    pythonWithPackages
  ] ++ commonCliTools;
in
delib.module {
  name = "krit.programs.claude-code-wrappers";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
    openrouterAliases = delib.boolOption (moduleSystem != "home");
  };

  myconfig.ifEnabled = { cfg, ... }: {
    programs.npm = {
      enable = lib.mkDefault true;
      packages = npmPackages;
      hostPackages = [
        pkgs.mpv # claudefm: playback
        pkgs.yt-dlp # claudefm: stream source
      ];
    };
    programs.claude-code.extraShellAliases = lib.optionalAttrs cfg.openrouterAliases openrouterAliases;
  };

  nixos.ifEnabled = _: {
    environment.systemPackages = sharedPackages ++ [
      pkgs.libreoffice
    ];
  };

  darwin.ifEnabled = _: {
    environment.systemPackages = sharedPackages;
    # Note: libreoffice not available on aarch64-darwin - install via Homebrew Cask if needed
  };
}
