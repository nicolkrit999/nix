{ delib, ... }:
delib.module {
  name = "programs.doom";

  home.ifEnabled = { ... }: {
    programs.doom-emacs.extraPackages = epkgs: [
      epkgs.treesit-grammars.with-all-grammars
    ];
  };
}
