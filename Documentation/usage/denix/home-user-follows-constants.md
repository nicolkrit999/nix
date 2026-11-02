# `homeUserFollowsConstants` (flake.nix)

`homeManagerUser` in `flake.nix` is evaluated before any config exists, so it is a fixed string (`"krit"`). By default denix therefore puts every `home.*` block under `home-manager.users.krit`. A specialisation that changes `myconfig.constants.user` (the school specialisation runs as `krit-school`) would still get its home-manager config on the wrong user.

The `homeUserFollowsConstants` denix extension in `flake.nix` replaces the `home` apply function with a module function that reads `config.myconfig.constants.user` of the evaluating (specialisation) config and sets `home-manager.users.${thatUser}`. For `constants.user = homeManagerUser`, as in every base configuration, nothing changes. It is skipped for `moduleSystem == "home"` and when `useHomeManagerModule` is off.

## Re-check on every denix bump

The extension depends on denix internals: `prev._callLibArgs` and its `apply` attrset (`apply.home`, `apply.listOfEverything`, `apply.myconfig`, `apply.nixos`, `apply.darwin`). If denix renames or restructures them the override silently stops applying or fails to evaluate. After bumping the denix input, verify that a specialisation with a different `constants.user` still lands its `home.*` options on that user (tests `nixos-spec-school` and `nixos-spec-contract` cover it).

## Hosts

`constants.user` in a host (for example `hosts/template-host-minimal/default.nix`) must equal `homeManagerUser` **only for the base configuration**; specialisations may override it with `mkForce` because of this extension.
