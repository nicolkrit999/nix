{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.lazygit";
  options = delib.singleEnableOption true;

  home.ifEnabled =
    { myconfig, ... }:
    {
      # -----------------------------------------------------------------------
      # 🎨 CATPPUCCIN THEME (official module)
      # -----------------------------------------------------------------------
      catppuccin.sources.lazygit =
        pkgs.runCommand "catppuccin-lazygit-migrated"
          { nativeBuildInputs = [ pkgs.yq-go ]; }
          ''
            cp -r ${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.lazygit} $out
            chmod -R u+w $out
            for f in $out/*/*.yml; do
              yq -i 'with(select(.gui.authorColors != null); .gui.theme.authorColors = .gui.authorColors | del(.gui.authorColors))' "$f"
            done
          '';
      catppuccin.lazygit.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.lazygit.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.lazygit.accent = myconfig.constants.theme.catppuccinAccent or "mauve";
      # -----------------------------------------------------------------------
      programs.lazygit = {
        enable = true;

        settings = {
          gui.showIcons = true;
          gui.quitOnTopLevelReturn = false;
          gui.skipNoPasswordPrompt = true;
          confirmOnQuit = false;
          git.overrideGpg = true;
        };
      };
    };
}
