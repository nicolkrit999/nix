{ pkgs }:
pkgs.writeShellApplication {
  name = "mango-pip";
  runtimeInputs = [ pkgs.jq pkgs.coreutils ];
  text = ''
    q() { mmsg get focusing-client | jq -r "$1" 2>/dev/null || echo null; }

    id=$(q '.id | tostring')
    if [[ $id == null ]]; then exit 0; fi
    dir="''${XDG_RUNTIME_DIR:-/tmp}/mango-pip"
    mkdir -p "$dir"

    if [[ $(q '.is_global | tostring') == true ]]; then
      mmsg dispatch toggleglobal
      if [[ -e $dir/$id ]]; then
        rm -f "$dir/$id"
      elif [[ $(q '.is_floating | tostring') == true ]]; then
        mmsg dispatch togglefloating
      fi
      exit 0
    fi

    floating=$(q '.is_floating | tostring')
    if [[ $floating == null ]]; then exit 0; fi
    if [[ $floating == false ]]; then
      mmsg dispatch togglefloating
    else
      touch "$dir/$id"
    fi
    if [[ $(q '.is_floating | tostring') == true ]]; then
      mmsg dispatch resizewin,800,450
      mmsg dispatch toggleglobal
    fi
  '';
}
