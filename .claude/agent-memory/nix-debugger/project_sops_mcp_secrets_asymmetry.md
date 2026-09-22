---
name: sops-mcp-secrets-asymmetry
description: claude_mcp_* sops secrets are wired asymmetrically - NixOS derives them from the mcpSecrets option list, Darwin hardcodes them; editing the darwin block is a no-op on Linux
metadata:
  type: project
---

`users/krit/common/toplevel/sops-secrets.nix` wires `claude_mcp_*` secrets **two different ways**, and the blocks look interchangeable but are not:

- `nixos.ifEnabled` and `home.ifEnabled` generate them programmatically from
  `myconfig.programs.claude-code.mcpSecrets` (via `mkClaudeMcpSecrets` / `mkClaudeMcpSecretsHome`).
- `darwin.ifEnabled` has a **hardcoded static list** of the same secret names.

So a new `claude_mcp_*` secret must be added to the `mcpSecrets` **default list** in
`modules/common/programs/claude-code.nix` - that is the single source of truth for Linux hosts.
Adding it only to the `darwin.ifEnabled` attrset is a silent no-op on NixOS: it evaluates
fine, `nix-instantiate --parse` passes, and the secret simply never appears in `/run/secrets/`.

Also note `hosts/Nicol-NAS/default.nix` **overrides** `mcpSecrets` with its own list, so it does
not pick up additions to the default - intentional, don't "fix" it.

**Why:** the darwin block predates the option-driven refactor and was never converted; the two
lists having near-identical contents makes the wrong one an easy target when adding a secret.

**How to apply:** when a sops secret "doesn't show up in /run/secrets" on a NixOS host, first check
whether it was declared in a Darwin-only block, and whether its name is in the `mcpSecrets` default
list. Verify with `nix eval .#nixosConfigurations.<host>.config.sops.secrets.<name>.path` rather
than a parse check - see [[flake-check-misses-build-failures]] for the general "parse/check is not
evaluation" lesson. Making the secret actually materialize still needs a real rebuild.
