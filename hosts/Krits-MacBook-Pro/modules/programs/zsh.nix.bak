{ delib, pkgs, ... }:
delib.module {
  name = "programs.zsh";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    let
      flakeDir = "~/nix-darwin-macOS";
    in
    {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        shellAliases = {
          brew-upd = "brew update && brew upgrade";
          brew-upd-res = "brew update-reset";
          brew-inst = "brew install";
          brew-inst-cask = "brew install --cask";
          brew-search = "brew search";
          brew-clean = "brew cleanup";
          sw = "cd ${flakeDir} && nh darwin switch ${flakeDir}";
          gsw = "git add -A && nh darwin switch ${flakeDir}";
          upd = "cd ${flakeDir} && nix flake update && sudo -H darwin-rebuild switch --flake ${flakeDir}";
          hms = "home-manager switch --flake ${flakeDir}";
          pkgs = "nvim ${flakeDir}/modules/";
          fmt = "cd ${flakeDir} && nix fmt -- **/*.nix";
          fmt-dry = "cd ${flakeDir} && nix fmt --check";
          caff = "caffeinate";
          xcodeaccept = "sudo xcodebuild -license accept";
          changehosts = "sudo nvim /etc/hosts";
          cleardns = "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder";
          fzf-prev = ''fzf --preview="cat {}"'';
          zlist = "zoxide query -l -s";
          tksession = "tmux kill-session -t";
          tks = "tmux kill-server";
          nixpush = "cd ~/nix-darwin-macOS/ && sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)";
          cdnix = "cd ~/nix-darwin-macOS/";
          nfc = "cd ${flakeDir} && nix flake check";
          nfcall = "cd ${flakeDir} && nix flake check --all-systems";
          swdry = "cd ${flakeDir} && nh darwin switch --dry ${flakeDir}";
        };

        initContent = ''
          if [ -f "$HOME/.zshrc_custom" ]; then
            source "$HOME/.zshrc_custom"
          fi

          if [[ -z "$TMUX" ]] && [[ "$-" == *i* ]]; then
            exec tmux new-session -A -s main
          fi

          export CASE_SENSITIVE="true"
          export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

          if [ -z "$SSH_AUTH_SOCK" ]; then
            eval "$(ssh-agent -s)" >/dev/null
            if [ -f "$HOME/.ssh/id_ed25519" ]; then
              ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" >/dev/null 2>&1 || true
            fi
          fi

          if [ -f "$HOME/.iterm2_shell_integration.zsh" ]; then
            . "$HOME/.iterm2_shell_integration.zsh"
          fi
        '';
      };
    };
}
