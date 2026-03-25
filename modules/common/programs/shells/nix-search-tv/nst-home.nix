{ delib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "programs.fzf.nix-search-tv";

  home.ifEnabled = {
    home.packages = [
      pkgs.nix-search-tv
      (pkgs.writeShellScriptBin "ns" ''
                export PATH="${pkgs.fzf}/bin:${pkgs.nix-search-tv}/bin:$PATH"

                # Ensure POSIX-compatible shell for subprocess compat (handles fish/nushell)
                case "$(basename "$SHELL")" in
                  bash | zsh | sh) ;;
                  *) SHELL="bash" ;;
                esac

                if [[ "$(uname)" == 'Darwin' ]]; then
                  SEARCH_SNIPPET_KEY="alt-w"
                  OPEN_SOURCE_KEY="alt-s"
                  OPEN_HOMEPAGE_KEY="alt-o"
                  PRINT_PREVIEW_KEY="alt-p"
                  OPENER="open"
                else
                  SEARCH_SNIPPET_KEY="ctrl-w"
                  OPEN_SOURCE_KEY="ctrl-s"
                  OPEN_HOMEPAGE_KEY="ctrl-o"
                  PRINT_PREVIEW_KEY="ctrl-p"
                  OPENER="xdg-open"
                fi

                CMD="''${NIX_SEARCH_TV:-nix-search-tv}"
                STATE_FILE="/tmp/nix-search-tv-fzf"
                echo "" > "$STATE_FILE"

                # Header text
                HEADER="$OPEN_HOMEPAGE_KEY open-homepage | $OPEN_SOURCE_KEY open-source | $SEARCH_SNIPPET_KEY github | $PRINT_PREVIEW_KEY pager
        ctrl-n nixpkgs | ctrl-h home-manager | ctrl-a all"

                # Build fzf arguments using arrays (avoids eval quoting issues)
                FZF_ARGS=(
                  --preview "$CMD preview \$(cat $STATE_FILE) {}"
                  --bind "$OPEN_SOURCE_KEY:execute($CMD source \$(cat $STATE_FILE) {} | xargs $OPENER)"
                  --bind "$OPEN_HOMEPAGE_KEY:execute($CMD homepage \$(cat $STATE_FILE) {} | xargs $OPENER)"
                  --bind "$SEARCH_SNIPPET_KEY:execute(echo {} | tr -d \"'\" | awk \"{if(\\\$2){print \\\$2}else print \\\$1}\" | xargs printf \"https://github.com/search?type=code&q=lang:nix+%s\" | xargs $OPENER)"
                  --bind "$PRINT_PREVIEW_KEY:execute($CMD preview \$(cat $STATE_FILE) {} | less)"
                  --layout reverse
                  --scheme history
                  --bind "resize,start:transform:if [[ \''${FZF_COLS:-\$COLUMNS} -lt 130 ]]; then echo +change-preview-window\(wrap,up\); else echo +change-preview-window\(wrap\); fi"
                  --header "$HEADER"
                  --header-first
                  --header-border
                  --header-label "Help"
                  # Index switching binds
                  --bind "ctrl-n:change-prompt(nixpkgs> )+change-preview($CMD preview --indexes nixpkgs {})+reload($CMD print --indexes nixpkgs)+execute-silent(echo --indexes nixpkgs > $STATE_FILE)"
                  --bind "ctrl-h:change-prompt(home-manager> )+change-preview($CMD preview --indexes home-manager {})+reload($CMD print --indexes home-manager)+execute-silent(echo --indexes home-manager > $STATE_FILE)"
                  --bind "ctrl-a:change-prompt(> )+change-preview($CMD preview {})+reload($CMD print)+execute-silent(echo > $STATE_FILE)"
                )

                $CMD print | fzf "''${FZF_ARGS[@]}"
      '')
    ];

    # Pre-warm the index on activation for plug-and-play UX (mirrors tv update-channels pattern)
    home.activation.updateNixSearchTvIndex =
      inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.nix-search-tv}/bin/nix-search-tv print > /dev/null 2>&1 || true
      '';
  };
}
