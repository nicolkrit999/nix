{
  description = "Dev environment for exam CHEAT SHEETS: Typst + LaTeX (Tectonic) + Pandoc, tuned for maximal-density A4 output and hard page-cap fitting (pdfinfo page counting + last-page ink measurement), with diagrams, plotting, code highlighting, and a Python scientific stack";

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
              typst # Typst compiler — near-instant recompiles (great for the fit loop);
              # native multi-column (`columns`), tables (`table`), code
              # highlighting (`raw`), and full math/symbol support built in.
              typstyle # Typst formatter

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
              echo "🗜️  cs-cheat-sheets: max-density A4 sheets + hard page-cap fitting"
              echo "------------------------------------------------------------------"
              check "Typst"    "typst --version"
              check "Tectonic" "tectonic --version"
              check "Pandoc"   "pandoc --version | head -n 1"
              check "pdfinfo"  "pdfinfo -v"
              check "pdftoppm" "pdftoppm -v"
              check "magick"   "magick --version | head -n 1 || convert --version | head -n 1"
              check "Graphviz" "dot -V"
              check "Gnuplot"  "gnuplot --version"
              check "Python"   "python3 --version"
              echo ""
              echo "Page-cap fit: pdfinfo cheatsheet.pdf | grep Pages   (count)"
              echo "Last-page full?  pdftoppm -png -f N -l N -r 100 ... | magick ... fx:1-mean"
              echo "Missing a tool? nix shell nixpkgs#<pkg> --command <cmd>, then ask to add it here."
              echo "------------------------------------------------------------------"
            '';
          };
        }
      );
    };
}
