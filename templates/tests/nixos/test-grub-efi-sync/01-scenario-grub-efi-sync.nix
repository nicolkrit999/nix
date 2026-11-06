let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hosts = [ "nixos-desktop" "nixos-laptop" ];

  scriptOf = host: flake.nixosConfigurations.${host}.config.boot.loader.grub.extraInstallCommands;
  grubOf = host: flake.nixosConfigurations.${host}.config.boot.loader.grub;

  has = re: s: builtins.match ".*${re}.*" s != null;

  verdict = ok: detail: if ok then "ok" else "FAIL: ${detail}";

  secureBootOf = host: flake.nixosConfigurations.${host}.config.myconfig.services.secure-boot.enable;

  noHookRule = grubEnabled: script: !grubEnabled && script == "";

  perHost = host:
    let s = scriptOf host; g = grubOf host; in
    {
      "mode-${host}" = if secureBootOf host then "lanzaboote" else "grub";
    }
    // (if secureBootOf host then {
      "check-${host}-lanzaboote-no-hook" = verdict (noHookRule g.enable s)
        "services.secure-boot is on but boot.loader.grub.enable=${lib.boolToString g.enable} and the stale-copy hook is ${if s == "" then "empty" else "non-empty"}";
    } else {
      "script-${host}" = s;
      "check-${host}-nonempty" = verdict (s != "") "extraInstallCommands is empty";
      "check-${host}-source-core" = verdict (has "/boot/grub/x86_64-efi/core\\.efi" s)
        "hook does not read /boot/grub/x86_64-efi/core.efi";
      "check-${host}-target-glob" = verdict (has "/boot/EFI/NixOS\\*/grubx64\\.efi" s)
        "hook does not target /boot/EFI/NixOS*/grubx64.efi";
      "check-${host}-no-set-e" = verdict (!(has "set -[a-z]*e" s))
        "hook contains set -e (would fail the rebuild)";
      "check-${host}-no-exit" = verdict (!(has "(^|[^a-zA-Z_])exit [0-9]" s))
        "hook contains an exit statement";
      "check-${host}-grub-efi-removable" = verdict (g.efiSupport && g.efiInstallAsRemovable)
        "grub efiSupport/efiInstallAsRemovable not both true (hook premise)";
    });
in
lib.foldl' (a: h: a // perHost h)
{
  control-no-hook-rule = verdict
    (noHookRule false "" && !noHookRule true "" && !noHookRule false "echo stale" && !noHookRule true "echo stale")
    "the lanzaboote-mode rule must accept only grub off with an empty hook";
}
  hosts
