{
  description = "Combined dev environment for CS / course notes: Typst + LaTeX (Tectonic) + Pandoc, with diagrams, plotting, PDF/image/SVG tooling, spell-check (EN/IT), and a Python scientific/stats stack for math figures";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
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

            shellHook = ''
              check() {
                local name="$1"
                local cmd="$2"
                local version=$(eval "$cmd" 2>&1 | head -n 1)
                if [ -n "$version" ]; then
                  printf "%-12s \033[0;32m✅ %s\033[0m\n" "$name" "$version"
                else
                  printf "%-12s \033[0;31m❌ Not Found\033[0m\n" "$name"
                fi
              }
              echo ""
              echo "------------------------------------------------------------------"
              echo "📝 cs-notes: Typst + LaTeX (Tectonic) + Pandoc + diagrams/math"
              echo "------------------------------------------------------------------"
              check "Typst"    "typst --version"
              check "Tectonic" "tectonic --version"
              check "Pandoc"   "pandoc --version | head -n 1"
              check "Graphviz" "dot -V"
              check "D2"       "d2 --version"
              check "Mermaid"  "mmdc --version"
              check "Gnuplot"  "gnuplot --version"
              check "Poppler"  "pdftotext -v"
              check "rsvg"     "rsvg-convert --version"
              check "Python"   "python3 --version"
              echo ""
              echo "Need a tool that's missing? Use it ad-hoc with"
              echo "  nix shell nixpkgs#<pkg> --command <cmd>"
              echo "then ask to add <pkg> to this flake.nix permanently."
              echo "------------------------------------------------------------------"
            '';
          };
        }
      );
    };
}
