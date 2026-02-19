{ config, ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;

    # Load custom path for ~/developing-projects to use
    # In a .envrc file type "use_dev_env or use_combined_env <language>"
    # Example: use_dev_env python or use_combined_env web-development/fullstack
    # It must match the name of the folder. E.g the argument replaces $1
    stdlib = ''
        use_dev_env() {
          # This dynamically inserts your home directory!
          # It resolves to: /home/krit/nixOS/hosts/...
          use flake ${config.home.homeDirectory}/nixOS/common/krit/modules/system/dev-environments/language-specific/$1
        }

        use_combined_env() {
        # $1 automatically accepts "deep" paths like "category/subdirectory"
        use flake ${config.home.homeDirectory}/nixOS/common/krit/modules/system/dev-environments/language-combined/$1
      }
    '';
  };
}
