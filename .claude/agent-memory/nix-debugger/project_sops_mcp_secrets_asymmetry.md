---
name: sops-mcp-secrets-asymmetry
description: claude_mcp_* sops secrets on all three platforms derive from the mcpSecrets option list; the NAS overrides it on purpose with only the secrets its launchers use
metadata:
  type: project
---

`users/krit/common/toplevel/sops-secrets.nix` generates `claude_mcp_*` secrets on **every** platform (`nixos.ifEnabled`, `home.ifEnabled` and `darwin.ifEnabled`) from
`myconfig.programs.claude-code.mcpSecrets`. The old darwin hardcoded list is gone.

A new `claude_mcp_*` secret therefore goes into the `mcpSecrets` **default list** in
`modules/common/programs/claude-code.nix` (entries are `{ sopsSecret = "..."; }`, the former `envVar` field was removed because nothing read it), plus the key in the common sops yaml.

`hosts/Nicol-NAS/default.nix` **overrides** `mcpSecrets` with just the two secrets its home-only launchers use (context7, github), so it does not pick up additions to the default - intentional, don't "fix" it.

**Why:** the option list is the single source of truth; the NAS needs fewer secrets and decrypting unused ones there is pointless.

**How to apply:** when a sops secret "doesn't show up in /run/secrets" on a host, check its name is in the `mcpSecrets` list that host actually uses (default vs NAS override). Verify with `nix eval .#nixosConfigurations.<host>.config.sops.secrets.<name>.path` rather than a parse check - see [[flake-check-misses-build-failures]]. Making the secret materialize still needs a real rebuild.
