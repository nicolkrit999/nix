{
  description = "Combined dev environment for CS / course notes: Typst + LaTeX (Tectonic) + Pandoc, with diagrams, plotting, PDF/image/SVG tooling, spell-check (EN/IT), and a Python scientific/stats stack for math figures";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              # ============================================================
              # Document toolchain
              # ============================================================
              typst # Typst compiler (lightweight; default for math/CS notes)
              typstyle # Typst formatter
              tinymist # Typst linter

              # Tectonic ships full LaTeX but fetches ONLY the packages each
              # document uses (cached), so there is no multi-GB texlive scheme.
              # Also usable as a pandoc PDF engine (--pdf-engine=tectonic).
              tectonic

              pandoc # md <-> pdf/typst/docx conversion
              haskellPackages.pandoc-crossref # figure/equation/section cross-refs for pandoc

              # ============================================================
              # Diagrams & plots (discrete math, automata, trees, CS arch)
              # ============================================================
              graphviz # `dot` - graphs, trees, automata
              d2 # modern diagram scripting (no browser needed)
              plantuml # UML diagrams (pulls a JRE)
              mermaid-cli # render mermaid -> svg/png/pdf (pulls Chromium)
              gnuplot # plotting for calculus / statistics

              # ============================================================
              # PDF / image / vector processing
              # ============================================================
              poppler-utils # pdftotext / pdfinfo / pdfimages - read source PDFs
              ghostscript # PDF/PS manipulation & compression
              imagemagick # raster figure conversion / resizing
              qpdf # lightweight PDF manipulation
              librsvg # `rsvg-convert` - SVG -> PDF/PNG
              inkscape # high-fidelity SVG -> PDF for figures

              # ============================================================
              # Misc
              # ============================================================
              jq # JSON wrangling (data for stats/plots)
              hunspell # spell-checker engine ...
              hunspellDicts.en_US # ... English (US)
              hunspellDicts.it_IT # ... Italian (notes are often written in Italian)

              # ============================================================
              # Python scientific / stats stack - verify math & generate
              # figures. Covers linear algebra, calculus, discrete/graph
              # theory, probability & statistics. `pygments` drives LaTeX
              # `minted` syntax-highlighted code listings.
              # ============================================================
              (python313.withPackages (ps: [
                ps.numpy
                ps.scipy
                ps.sympy # symbolic math (linear algebra, calculus)
                ps.matplotlib # plots/figures to embed
                ps.seaborn # statistical plotting
                ps.pandas
                ps.statsmodels # statistical models / regression
                ps.scikit-learn # ML / data (for CS-data courses)
                ps.networkx # graph theory / discrete math
                ps.ipython # interactive exploration
                ps.pygments # syntax highlighting for minted
                ps.genanki # build Anki decks (.apkg) - exporting-anki-decks skill
              ]))
            ];

            # Entry banner: tool versions + overall verdict (never aborts the shell)
            shellHook = ''
                            # --- dev-env status banner (self-contained; removes itself in check_done) ---
              check_begin() { # check_begin <env name> <system>
                __de_ok=0 __de_total=0 __de_missing="" __de_g="" __de_r="" __de_y="" __de_b="" __de_n=""
                if [ -t 1 ] && [ -z "''${NO_COLOR:-}" ]; then
                  __de_g='\033[0;32m' __de_r='\033[0;31m' __de_y='\033[0;33m' __de_b='\033[1m' __de_n='\033[0m'
                fi
                __de_name="$1"
                printf '\n%b🚀 %s%b  (%s)\n' "$__de_b" "$1" "$__de_n" "$2"
                printf -- '------------------------------------------------------------\n'
              }
              check() { # check <label> "<version cmd>" ["<alternate cmd>" ...]
                local label="$1" cmd out ver rc
                shift
                __de_total=$((__de_total + 1))
                for cmd in "$@"; do
                  command -v "''${cmd%% *}" >/dev/null 2>&1 || continue
                  out=$(eval "$cmd" 2>/dev/null </dev/null); rc=$?
                  ver=$(printf '%s\n' "$out" | head -n 3 | grep -oE '[0-9]+(\.[0-9]+)+' | head -n 1)
                  if [ -z "$out" ]; then # stdout empty: the version may be on stderr (java -version)
                    out=$(eval "$cmd" 2>&1 </dev/null)
                    ver=$(printf '%s\n' "$out" | head -n 3 | grep -oE '[0-9]+(\.[0-9]+)+' | head -n 1)
                  fi
                  __de_ok=$((__de_ok + 1))
                  if [ -n "$ver" ]; then
                    printf "  %b✅ %-20s%b %s\n" "$__de_g" "$label" "$__de_n" "$ver"
                  elif [ "$rc" -eq 0 ]; then
                    printf "  %b✅ %-20s%b %s\n" "$__de_g" "$label" "$__de_n" "installed"
                  else
                    printf "  %b⚠️  %-20s%b %s\n" "$__de_y" "$label" "$__de_n" "installed (version unknown)"
                  fi
                  return 0
                done
                __de_missing="$__de_missing''${__de_missing:+, }$label"
                printf "  %b❌ %-20s%b %s\n" "$__de_r" "$label" "$__de_n" "not found"
                return 0
              }
              check_section() { printf '%b%s%b\n' "$__de_b" "$1" "$__de_n"; }
              check_done() {
                printf -- '------------------------------------------------------------\n'
                if [ -z "$__de_missing" ]; then
                  printf "%b✅ %s ready: %s/%s tools%b\n\n" "$__de_g" "$__de_name" "$__de_ok" "$__de_total" "$__de_n"
                else
                  printf "%b⚠️  %s incomplete (%s/%s): missing %s%b\n\n" "$__de_y" "$__de_name" "$__de_ok" "$__de_total" "$__de_missing" "$__de_n"
                fi
                unset -f check_begin check check_section check_done
                unset __de_ok __de_total __de_missing __de_name __de_g __de_r __de_y __de_b __de_n
              }

                            check_begin "cs-notes" "${pkgs.stdenv.hostPlatform.system}"
                            check_section "--- Documents ---"
                            check "Typst" "typst --version"
                            check "Typstyle" "typstyle --version"
                            check "Tinymist" "command -v tinymist >/dev/null && echo installed"
                            check "Tectonic" "tectonic --version"
                            check "Pandoc" "pandoc --version"
                            check "pandoc-crossref" "pandoc-crossref --version"
                            check_section "--- Diagrams / plots ---"
                            check "Graphviz" "dot -V"
                            check "D2" "d2 --version"
                            check "PlantUML" "plantuml -version"
                            check "Mermaid" "mmdc --version"
                            check "Gnuplot" "gnuplot --version"
                            check_section "--- PDF / images ---"
                            check "pdftotext" "pdftotext -v"
                            check "pdfinfo" "pdfinfo -v"
                            check "ImageMagick" "magick --version"
                            check "Ghostscript" "gs --version"
                            check "qpdf" "qpdf --version"
                            check "rsvg-convert" "rsvg-convert --version"
                            check "Inkscape" "inkscape --version"
                            check_section "--- Misc ---"
                            check "jq" "jq --version"
                            check "Hunspell" "hunspell --version | grep -o 'Hunspell [0-9.]*'"
                            check "Python" "python3 --version" "python --version"
                            check "IPython" "ipython --version"
                            check_done
            '';
          };
        }
      );
    };
}
