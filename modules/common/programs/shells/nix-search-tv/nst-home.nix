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

                declare -a INDEXES=( "nixpkgs ctrl-n" "home-manager ctrl-h" "all ctrl-a" )

                bind_index() {
                    local key="$1" index="$2" prompt="" indexes_flag=""
                    if [[ -n "$index" && "$index" != "all" ]]; then
                        indexes_flag="--indexes $index"
                        prompt=$index
                    fi
                    echo "$key:change-prompt($prompt> )+change-preview($CMD preview $indexes_flag {})+reload($CMD print $indexes_flag)"
                }

                STATE_FILE="/tmp/nix-search-tv-fzf"

                save_state() {
                    local index="$1" indexes_flag=""
                    if [[ -n "$index" && "$index" != "all" ]]; then
                        indexes_flag="--indexes $index"
                    fi
                    echo "execute(echo $indexes_flag > $STATE_FILE)"
                }

                HEADER="$OPEN_HOMEPAGE_KEY open-homepage | $OPEN_SOURCE_KEY open-source | $SEARCH_SNIPPET_KEY github | $PRINT_PREVIEW_KEY pager
        ctrl-n nixpkgs | ctrl-h home-manager | ctrl-a all"

                FZF_BINDS=""
                for e in "''${INDEXES[@]}"; do
                    index=$(echo "$e" | awk '{ print $1 }')
                    keybind=$(echo "$e" | awk '{ print $2 }')
                    FZF_BINDS="$FZF_BINDS --bind '$(bind_index "$keybind" "$index")+$(save_state "$index")'"
                done

                echo "" > "$STATE_FILE"

                # shellcheck disable=SC2016
                SEARCH_SNIPPET_CMD=$'echo \"{}\"'
                SEARCH_SNIPPET_CMD="$SEARCH_SNIPPET_CMD | tr -d \"'\" "
                SEARCH_SNIPPET_CMD="$SEARCH_SNIPPET_CMD | awk '{ if (\$2) { print \$2 } else print \$1 }' "
                SEARCH_SNIPPET_CMD="$SEARCH_SNIPPET_CMD | xargs printf \"https://github.com/search?type=code&q=lang:nix+%s\""

                # shellcheck disable=SC2016
                PREVIEW_WINDOW='
                    if [[ ''${FZF_COLS:-$COLUMNS} -lt 130 ]]; then
                        echo "+change-preview-window(wrap,up)"
                    else
                        echo "+change-preview-window(wrap)"
                    fi
                '

                eval "$CMD print | fzf \
                    --preview '$CMD preview \$(cat $STATE_FILE) {}' \
                    --bind '$OPEN_SOURCE_KEY:execute($CMD source \$(cat $STATE_FILE) {} | xargs $OPENER)' \
                    --bind '$OPEN_HOMEPAGE_KEY:execute($CMD homepage \$(cat $STATE_FILE) {} | xargs $OPENER)' \
                    --bind \$'$SEARCH_SNIPPET_KEY:execute($SEARCH_SNIPPET_CMD | xargs $OPENER)' \
                    --bind \$'$PRINT_PREVIEW_KEY:execute($CMD preview \$(cat $STATE_FILE) {} | less)' \
                    --layout reverse \
                    --scheme history \
                    --bind 'resize,start:transform:\$PREVIEW_WINDOW' \
                    --header '\$HEADER' \
                    --header-first \
                    --header-border \
                    --header-label \"Help\" \
                    \$FZF_BINDS
                "
      '')
    ];

    # Pre-warm the index on activation for plug-and-play UX (mirrors tv update-channels pattern)
    home.activation.updateNixSearchTvIndex =
      inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.nix-search-tv}/bin/nix-search-tv print > /dev/null 2>&1 || true
      '';
  };
}
