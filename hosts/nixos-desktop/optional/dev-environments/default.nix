{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  vars = import ../../variables.nix;
  langs = vars.devLanguages; # e.g. ["java" "rust"]
in
{
  config = lib.mkMerge [

    # --- C/C++ ---
    (lib.mkIf (builtins.elem "c-cpp" langs) {
      environment.systemPackages = import ./c-cpp/packages.nix { inherit pkgs; };
    })

    # --- GO ---
    (lib.mkIf (builtins.elem "go" langs) {
      environment.systemPackages = import ./go/packages.nix { inherit pkgs; };
    })

    # --- HASKELL ---
    (lib.mkIf (builtins.elem "haskell" langs) {
      environment.systemPackages = import ./haskell/packages.nix { inherit pkgs; };
    })

    # --- JAVA ---
    (lib.mkIf (builtins.elem "java" langs) {
      environment.systemPackages = import ./java/packages.nix { inherit pkgs; };
    })

    # --- JUPYTER ---
    (lib.mkIf (builtins.elem "jupyter" langs) {
      environment.systemPackages = import ./jupyter/packages.nix { inherit pkgs; };
    })

    # --- LATEX ---
    (lib.mkIf (builtins.elem "latex" langs) {
      environment.systemPackages = import ./latex/packages.nix { inherit pkgs; };
    })

    # --- NIX ---
    (lib.mkIf (builtins.elem "nix" langs) {
      environment.systemPackages = import ./nix/packages.nix { inherit pkgs; };
    })

    # --- NODE / JS ---
    (lib.mkIf (builtins.elem "node" langs) {
      environment.systemPackages = import ./node/packages.nix { inherit pkgs; };
    })

    # --- PHP ---
    (lib.mkIf (builtins.elem "php" langs) {
      environment.systemPackages = import ./php/packages.nix { inherit pkgs; };
    })

    # --- PYTHON ---
    (lib.mkIf (builtins.elem "python" langs) {
      environment.systemPackages = import ./python/packages.nix { inherit pkgs; };
    })

    # --- R ---
    (lib.mkIf (builtins.elem "r" langs) {
      environment.systemPackages = import ./r/packages.nix { inherit pkgs; };
    })

    # --- RUST ---
    (lib.mkIf (builtins.elem "rust" langs) {
      environment.systemPackages =
        let
          stableToolchain = pkgs.symlinkJoin {
            name = "rust-toolchain";
            paths = with pkgs; [
              rustc
              cargo
              clippy
              rustfmt
            ];
          };
        in
        import ./rust/packages.nix {
          inherit pkgs;
          rustToolchain = stableToolchain;
        };
    })

    # --- SHELL ---
    (lib.mkIf (builtins.elem "shell" langs) {
      environment.systemPackages = import ./shell/packages.nix { inherit pkgs; };
    })

    # --- SWIFT ---
    (lib.mkIf (builtins.elem "swift" langs) {
      environment.systemPackages = import ./swift/packages.nix { inherit pkgs; };
    })

    # --- TYPST ---
    (lib.mkIf (builtins.elem "typst" langs) {
      environment.systemPackages = import ./typst/packages.nix { inherit pkgs; };
    })
  ];
}
