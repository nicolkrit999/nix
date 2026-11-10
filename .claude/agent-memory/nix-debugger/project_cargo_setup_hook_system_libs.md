---
name: cargo-setup-hook-system-libs
description: nixpkgs cargoSetupHook cargoUseSystemLibs forces *_USE_SYSTEM/PKG_CONFIG env (AWS_LC_SYS_USE_SYSTEM, LIBSQLITE3_SYS_USE_PKG_CONFIG...) - Rust pkgs missing the lib in buildInputs fail (evebox sqlite, tectonic aws-lc, 2026-11)
metadata:
  type: project
---
Since late 2026 nixpkgs `pkgs/build-support/rust/hooks/cargo-setup-hook.sh` runs `cargoUseSystemLibs` (opt-out `dontCargoUseSystemLibs`) for every buildRustPackage, exporting AWS_LC_SYS_USE_SYSTEM=1, OPENSSL_NO_VENDOR, LIBSQLITE3_SYS_USE_PKG_CONFIG=1, ZSTD/LIBGIT2/SODIUM/ONIG system flags. Packages that vendored those libs and lack them in buildInputs panic in build scripts.

**Why:** caused two separate "after flake update" failures: evebox (sqlite) and tectonic 0.17.0 (aws-lc-sys 0.42 "requires a system-installed AWS-LC", fixed upstream master 743696b736 on 2026-11-08). Hydra fails them too (same drv as vanilla, narinfo 404).

**How to apply:** for a Rust build-script panic mentioning system lib / pkg-config after a bump, first compare drv with vanilla nixpkgs at the locked rev, then check master for "fix build with system libs" commits; fix = self-disabling overlay adding the lib to buildInputs (modules/nixos/toplevel/*-overlay.nix pattern). Overlaying `tectonic-unwrapped` propagates to the `tectonic` wrapper.
