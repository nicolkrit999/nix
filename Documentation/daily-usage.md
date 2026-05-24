# Daily Usage & Updates

After editing any file, use these aliases to apply changes. They require `programs.nh.enable = true` (enabled by default).

| Alias | Command | Description |
|-------|---------|-------------|
| `sw` | `nh os switch` | Rebuild everything (system + home-manager) |
| `upd` | `nh os switch --update` | Update all flake inputs, then rebuild |

Both commands handle system and home-manager rebuilds in one step.

### Cachix integration

When Cachix is enabled on a host, `sw` and `upd` automatically pull pre-built binaries from the cache instead of compiling locally — significantly faster on a good connection.

If a host is configured as a **builder** (push role), the same aliases also push the freshly built derivations to Cachix after a successful switch, keeping the cache up to date for other machines.
