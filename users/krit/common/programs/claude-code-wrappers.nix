{ delib, pkgs, ... }:
let
  # Shared shell script wrappers
  caiScript = pkgs.writeShellScriptBin "cai" ''
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
      python-docx # docx skill — creation/editing
      openpyxl # xlsx creation/editing
      pillow # pptx thumbnail grids, image handling
      pypdf # pdf skill — merge/split/metadata
      pdfplumber # pdf skill — text/table extraction
      python-pptx # pptx skill — presentation creation
      reportlab # pdf skill — create PDFs
      requests # citation-management, literature-review
      bibtexparser # citation-management — BibTeX parsing
      biopython # citation-management — PubMed access
      scholarly # citation-management — Google Scholar
      markitdown # markitdown skill — file-to-markdown
    ]
  );

  # Shared CLI tools
  commonCliTools = [
    pkgs.pandoc # docx/literature-review — text extraction and PDF generation
    pkgs.octave # Matlab skill - numerical computing, plotting, data analysis
    pkgs.poppler-utils # pdf/pptx/docx — pdftoppm, pdftotext, pdfimages
    pkgs.tesseract # pdf — OCR for scanned documents
    pkgs.uv # fast Python package installer (fallback for non-nix envs)
  ];

  # All shared packages
  sharedPackages = [
    caiScript
    caiSubScript
    caiOpenrouterScript
    pythonWithPackages
  ] ++ commonCliTools;
in
delib.module {
  name = "krit.programs.claude-code-wrappers";

  options.krit.programs.claude-code-wrappers = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled = { ... }: {
    environment.systemPackages = sharedPackages ++ [
      # NixOS-only packages
      pkgs.libreoffice-still
    ];
  };

  darwin.ifEnabled = { ... }: {
    environment.systemPackages = sharedPackages;
    # Note: libreoffice-still not available on aarch64-darwin — install via Homebrew Cask if needed
  };
}
