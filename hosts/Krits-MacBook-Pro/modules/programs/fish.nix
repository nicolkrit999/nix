{ delib, lib, ... }:
delib.module {
  name = "programs.fish";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    let
      flakeDir = "~/nix-darwin-macOS";
    in
    lib.mkIf ((myconfig.constants.shell or "zsh") == "fish") {
      programs.fish = {
        enable = true;

        shellAbbrs = {
          brew-upd = "brew update && brew upgrade";
          brew-upd-res = "brew update-reset";
          brew-inst = "brew install";
          brew-inst-cask = "brew install --cask";
          brew-search = "brew search";
          brew-clean = "brew cleanup";
          sw = "cd ${flakeDir} && nh darwin switch ${flakeDir}";
          gsw = "cd ${flakeDir} && git add -A && nh darwin switch ${flakeDir}";
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

        interactiveShellInit = ''
          if test -f "$HOME/.custom.fish"
            source "$HOME/.custom.fish"
          end

          if status is-interactive
            and not set -q TMUX
            exec tmux new-session -A -s main
          end

          set -U fish_greeting

          bind --erase --all alt-c
          bind ctrl-g fzf-cd-widget
        '';

        functions = {
          npu = ''
            set url ""
            if test -n "$argv[1]"
                set url "$argv[1]"
            else
                read -P "🔗 Enter URL: " url
            end

            if test -z "$url"
                echo "❌ No URL provided."
                return 1
            end

            if string match -q "https://github.com/*/blob/*" -- "$url"
                set url (string replace "github.com" "raw.githubusercontent.com" "$url" | string replace "/blob/" "/")
                echo "🔄 Converted Github Blob to Raw"
            end

            set args

            if string match -q "https://github.com/*" -- "$url"
                if string match -q "*/commit/*" -- "$url"
                    set url (string replace "/commit/" "/archive/" "$url").tar.gz
                    set args --unpack
                    echo "📦 Detected Github Commit -> Downloading Archive"
                else if string match -q "*/releases/tag/*" -- "$url"
                    set url (string replace "/releases/tag/" "/archive/refs/tags/" "$url").tar.gz
                    set args --unpack
                    echo "📦 Detected Github Release -> Downloading Archive"
                else if string match -q "*/tree/*" -- "$url"
                    set url (string replace "/tree/" "/archive/refs/heads/" "$url").tar.gz
                    set args --unpack
                    echo "📦 Detected Github Branch -> Downloading Archive"
                end
            end

            if test -z "$args"
                set filename (basename "$url")
                if command -q python3
                    set decoded_name (python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$filename")
                    if test "$filename" != "$decoded_name"
                        set args --name "$decoded_name"
                        echo "✨ Decoded filename: '$decoded_name'"
                    end
                end
            end

            nix-prefetch-url $args "$url"
          '';
        };
      };
    };
}
