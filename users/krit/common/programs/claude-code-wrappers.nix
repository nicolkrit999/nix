{ delib, pkgs, ... }:
let
  # Shared shell script wrappers
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
    exec ${pkgs.claude-code}/bin/claude "$@"
  '';

  caiSubScript = pkgs.writeShellScriptBin "cai-sub" ''
    exec env \
      -u ANTHROPIC_BASE_URL \
      -u ANTHROPIC_AUTH_TOKEN \
      -u ANTHROPIC_MODEL \
      -u ANTHROPIC_API_KEY \
      -u OPENROUTER_API_KEY \
      ${pkgs.claude-code}/bin/claude "$@"
  '';

  # Cloud session on the normal Anthropic route. Cloud sessions run on
  # Anthropic's side, so any OpenRouter/custom-endpoint env is stripped.
  # `claude --cloud` needs a task description: if none was given, ask for it
  # and pass it straight through instead of failing.
  ccaiScript = pkgs.writeShellScriptBin "ccai" ''
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

    exec env \
      -u ANTHROPIC_BASE_URL \
      -u ANTHROPIC_AUTH_TOKEN \
      -u ANTHROPIC_MODEL \
      -u ANTHROPIC_API_KEY \
      -u OPENROUTER_API_KEY \
      ${pkgs.claude-code}/bin/claude --cloud "$desc" "''${flags[@]}"
  '';

  caiOpenrouterScript = pkgs.writeShellScriptBin "cai-openrouter" ''
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
  '';

  # Shared Python packages for skills
  pythonWithPackages = pkgs.python313.withPackages (
    ps: with ps; [
      litellm # perplexity-search, generate-image, infographics
      matplotlib # matplotlib skill
      networkx # networkx skill
      pandas # xlsx, data analysis
      python-docx # docx skill - creation/editing
      openpyxl # xlsx creation/editing
      pillow # pptx thumbnail grids, image handling
      pypdf # pdf skill - merge/split/metadata
      pdfplumber # pdf skill - text/table extraction
      python-pptx # pptx skill - presentation creation
      reportlab # pdf skill - create PDFs
      requests # citation-management, literature-review
      bibtexparser # citation-management - BibTeX parsing
      biopython # citation-management - PubMed access
      scholarly # citation-management - Google Scholar
      markitdown # markitdown skill - file-to-markdown
    ]
    ++ markitdown.optional-dependencies.all # docx/xlsx/xls/pdf/pptx/audio/youtube/outlook converters
    ++ litellm.optional-dependencies.proxy # litellm CLI and proxy server (rich, typer, websockets)
  );

  # Shared CLI tools
  commonCliTools = [
    pkgs.pandoc # docx/literature-review - text extraction and PDF generation
    pkgs.octave # Matlab skill - numerical computing, plotting, data analysis
    pkgs.poppler-utils # pdf/pptx/docx - pdftoppm, pdftotext, pdfimages
    pkgs.tesseract # pdf - OCR for scanned documents
    pkgs.uv # fast Python package installer (fallback for non-nix envs)
  ];

  # All shared packages
  sharedPackages = [
    caiScript
    caiSubScript
    ccaiScript
    caiOpenrouterScript
    pythonWithPackages
  ] ++ commonCliTools;
in
delib.module {
  name = "krit.programs.claude-code-wrappers";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = { ... }: {
    environment.systemPackages = sharedPackages ++ [
      # NixOS-only packages
      pkgs.libreoffice
    ];
  };

  darwin.ifEnabled = { ... }: {
    environment.systemPackages = sharedPackages;
    # Note: libreoffice not available on aarch64-darwin - install via Homebrew Cask if needed
  };
}
