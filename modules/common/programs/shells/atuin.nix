{ delib, lib, ... }:
delib.module {
  name = "programs.atuin";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    let
      currentShell = myconfig.constants.shell or "zsh";
    in
    {
      programs.atuin = {
        enable = true;
        enableZshIntegration = currentShell == "zsh";
        enableFishIntegration = currentShell == "fish";
        enableBashIntegration = currentShell == "bash";
        flags = [ "--disable-ctrl-r" ];
      };

      programs.fish.interactiveShellInit = lib.mkIf (currentShell == "fish") (lib.mkAfter ''
        bind ctrl-o _atuin_search
        if bind -M insert >/dev/null 2>&1
          bind -M insert ctrl-o _atuin_search
        end
      '');

      programs.zsh.initContent = lib.mkIf (currentShell == "zsh") (lib.mkAfter ''
        if (( $+widgets[atuin-search] )); then
          bindkey -M emacs '^o' atuin-search
          bindkey -M viins '^o' atuin-search-viins
          bindkey -M vicmd '^o' atuin-search-vicmd
        fi
      '');

      programs.bash.initExtra = lib.mkIf (currentShell == "bash") (lib.mkAfter ''
        if declare -F atuin-bind >/dev/null; then
          atuin-bind -m emacs '\C-o' atuin-search-emacs
          atuin-bind -m vi-insert '\C-o' atuin-search-viins
        fi
      '');
    };
}
