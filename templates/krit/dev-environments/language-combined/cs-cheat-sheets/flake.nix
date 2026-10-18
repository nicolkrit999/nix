{
  description = "Dev environment for exam CHEAT SHEETS: Typst + LaTeX (Tectonic) + Pandoc, tuned for maximal-density A4 output and hard page-cap fitting (pdfinfo page counting + last-page ink measurement), with diagrams, plotting, code highlighting, and a Python scientific stack";

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
              typst # Typst compiler — near-instant recompiles (great for the fit loop);
              # native multi-column (`columns`), tables (`table`), code
              # highlighting (`raw`), and full math/symbol support built in.
              typstyle # Typst formatter
              tinymist # Typst language server

              # Tectonic ships full LaTeX and fetches ONLY the packages each
              # document uses (cached) — so ALL the cheat-sheet layout packages
              # come down automatically on first use, no multi-GB texlive scheme:
              #   multicol/paracol (columns) · geometry (tiny margins) ·
              #   tabularx/booktabs/array/makecell (dense tables) ·
              #   amsmath/amssymb/mathtools (math symbols) · graphicx (images) ·
              #   listings (code, shell-escape-free) · xcolor/tcolorbox (boxed
              #   highlights) · enumitem (compact lists) · microtype (tighter fill).
              tectonic

              pandoc # md <-> pdf/typst conversion
              haskellPackages.pandoc-crossref # cross-refs for pandoc

              # ============================================================
              # PDF measurement — THE core of page-cap fitting
              # ============================================================
              poppler-utils # pdfinfo (page count), pdftoppm (render a page to image)
              imagemagick # measure last-page ink coverage -> "is the last page full?"
              ghostscript # PDF/PS manipulation & compression
              qpdf # lightweight PDF manipulation
              librsvg # rsvg-convert — SVG -> PDF/PNG
              inkscape # high-fidelity SVG -> PDF for embedded figures

              # ============================================================
              # Small diagrams & plots (occasionally embedded in a cheat sheet)
              # ============================================================
              graphviz # `dot` — graphs, trees, automata
              d2 # modern diagram scripting
              gnuplot # plotting for calculus / statistics

              # ============================================================
              # Misc
              # ============================================================
              jq # JSON wrangling
              hunspell # spell-checker engine ...
              hunspellDicts.en_US # ... English (US)
              hunspellDicts.it_IT # ... Italian (sheets are often written in Italian)

              # ============================================================
              # Python scientific / stats stack — verify formulas before they
              # go on the sheet & generate any embedded figure. `pygments`
              # drives LaTeX `minted` syntax-highlighted code listings (common
              # on programming cheat sheets).
              # ============================================================
              (python313.withPackages (ps: [
                ps.numpy
                ps.scipy
                ps.sympy # symbolic math (linear algebra, calculus)
                ps.matplotlib # plots/figures to embed
                ps.pandas
                ps.statsmodels # statistical models / regression
                ps.networkx # graph theory / discrete math
                ps.pygments # syntax highlighting for minted
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

                            check_begin "cs-cheat-sheets" "${pkgs.stdenv.hostPlatform.system}"
                            check_section "--- Documents ---"
                            check "Typst" "typst --version"
                            check "Typstyle" "typstyle --version"
                            check "Tinymist" "command -v tinymist >/dev/null && echo installed"
                            check "Tectonic" "tectonic --version"
                            check "Pandoc" "pandoc --version"
                            check "pandoc-crossref" "pandoc-crossref --version"
                            check_section "--- PDF / images ---"
                            check "pdfinfo" "pdfinfo -v"
                            check "pdftoppm" "pdftoppm -v"
                            check "ImageMagick" "magick --version"
                            check "Ghostscript" "gs --version"
                            check "qpdf" "qpdf --version"
                            check "rsvg-convert" "rsvg-convert --version"
                            check "Inkscape" "inkscape --version"
                            check_section "--- Diagrams / plots ---"
                            check "Graphviz" "dot -V"
                            check "D2" "d2 --version"
                            check "Gnuplot" "gnuplot --version"
                            check_section "--- Misc ---"
                            check "jq" "jq --version"
                            check "Hunspell" "hunspell --version | grep -o 'Hunspell [0-9.]*'"
                            check "Python" "python3 --version" "python --version"
                            check_done
            '';
          };
        }
      );
    };
}
