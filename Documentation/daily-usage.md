# Daily Usage & Updates

After editing any file, use these aliases to apply changes. They require `programs.nh.enable = true` (enabled by default).

| Alias | Command | Description |
|-------|---------|-------------|
| `sw` | `nh os switch ~/nix` | Rebuild everything (system + home-manager) |
| `upd` | `git add -A`, then `nh os switch --update ~/nix` | Update all flake inputs, then rebuild |

Other variants (`gsw`, `swoff`, `gswoff`, `swdry`, `swpure`) are defined in `modules/common/programs/shells/shell-aliases.nix`. On Darwin the aliases use `nh darwin switch`; in standalone home builds they use `home-manager switch`.

Both commands handle system and home-manager rebuilds in one step.

### Cachix integration

When Cachix is enabled on a host, `sw` and `upd` automatically pull pre-built binaries from the cache instead of compiling locally — significantly faster on a good connection.

If a host is configured as a **builder** (push role), the same aliases also push the current system closure to Cachix (and to the NAS attic cache when `myconfig.attic.push` is set) after the switch; a failed push never fails the rebuild. The manual aliases are `cachix-push` and `attic-push`.
