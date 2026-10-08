---
name: input-glibc-vs-opengl-driver
description: GUI app from a flake input with its own (older) nixpkgs can't dlopen the system mesa from /run/opengl-driver when system glibc is newer; shows as "EGL not available" / QRhiGles2 context failure
metadata:
  type: project
---

GL apps built from flake inputs that do NOT follow our nixpkgs run with their own glibc, but libglvnd dlopens the host's mesa from /run/opengl-driver. When our nixpkgs runs ahead (2026-10-08: mesa 26.2.4 libgallium needs GLIBC_2.43, vicinae's nixpkgs had glibc 2.42), the driver load fails silently: vicinae logged `warn - EGL not available`, then `QRhiGles2: Failed to create context` -> `FATAL - Failed to initialize graphics backend for OpenGL` -> SIGABRT on first window show. The vicinae package itself was byte-identical before/after the unstable switch; only /run/opengl-driver changed.

**Why:** the failure looks like a GPU/Wayland/Qt bug but is an ABI mismatch between the process's glibc and the driver's.

**How to apply:** compare `ldd <bin> | grep libc.so` with `ldd /run/opengl-driver/lib/libgallium-*.so` / `objdump -T ... | grep GLIBC_2.4`. Fix = `inputs.nixpkgs.follows = "nixpkgs"` on that input (loses the upstream cachix hit; builds locally). Other inputs with independent nixpkgs at that time: walker, elephant, nix-alien, tgt, vicinae-extensions (list via flake.lock root inputs).
