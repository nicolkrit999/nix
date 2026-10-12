{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.lazygit";
  options = delib.singleEnableOption true;

  home.ifEnabled =
    { myconfig, ... }:
    {
      catppuccin = {
        # TEMP: catppuccin lazygit theme patched (authorColors -> gui.theme); see memory project_lazygit_catppuccin_migrated_workaround
        sources.lazygit =
          pkgs.runCommand "catppuccin-lazygit-migrated"
            { nativeBuildInputs = [ pkgs.yq-go ]; }
            ''
              cp -r ${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.lazygit} $out
              chmod -R u+w $out
              for f in $out/*/*.yml; do
                yq -i 'with(select(.gui.authorColors != null); .gui.theme.authorColors = .gui.authorColors | del(.gui.authorColors))' "$f"
              done
            '';
        lazygit = {
          enable = myconfig.constants.theme.catppuccin;
          flavor = myconfig.constants.theme.catppuccinFlavor;
          accent = myconfig.constants.theme.catppuccinAccent;
        };
      };

      programs.lazygit = {
        enable = true;

        settings = {
          gui = {
            nerdFontsVersion = "2";
            quitOnTopLevelReturn = false;
          };
          confirmOnQuit = false;
          git.overrideGpg = true;
        };
      };
    };
}
