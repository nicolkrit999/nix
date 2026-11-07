{ pkgs }:
let
  inherit (pkgs) lib;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./install.sh
      ./disk-plan.sh
      ./layout.nix
      ./make-bundle.sh
      ./repo-url.txt
    ];
  };

  repoUrl = lib.fileContents ./repo-url.txt;

  tools = with pkgs; [
    nix
    bash
    coreutils
    findutils
    gawk
    gnugrep
    gnused
    gnutar
    util-linux
    gptfdisk
    parted
    systemd
    jq
    git
    curl
    age
    sops
    ssh-to-age
    tailscale
    sbctl
    efibootmgr
    nixos-install-tools
    dosfstools
    btrfs-progs
    cryptsetup
  ];

  installer = pkgs.writeShellApplication {
    name = "clone-installer";
    runtimeInputs = tools;
    text = ''
      export INSTALLER_LIVE=1
      exec ${src}/install.sh "$@"
    '';
    meta.mainProgram = "clone-installer";
  };

  make-bundle = pkgs.writeShellApplication {
    name = "clone-make-bundle";
    runtimeInputs = with pkgs; [ age gnutar coreutils util-linux getent gnugrep findutils ];
    text = ''
      exec ${src}/make-bundle.sh "$@"
    '';
    meta.mainProgram = "clone-make-bundle";
  };

  clone-install = pkgs.writeShellApplication {
    name = "clone-install";
    runtimeInputs = tools;
    text = ''
      url=''${INSTALLER_REPO_URL:-${repoUrl}}
      export GIT_TERMINAL_PROMPT=0

      if [ "$(id -u)" -ne 0 ]; then
        exec /run/wrappers/bin/sudo "$0" "$@"
      fi

      until git ls-remote --exit-code --heads "$url" main >/dev/null 2>&1; do
        echo "Cannot reach $url (no network?)." >&2
        echo "  Wired: plug in a cable and retry." >&2
        echo "  Wi-Fi: run 'nmtui' in another console (Alt+F2) or: nmcli device wifi connect SSID password PASSWORD" >&2
        printf '[r]etry / [q]uit: ' >&2
        read -r answer || exit 1
        case $answer in
          q | Q) exit 1 ;;
        esac
      done

      work=$(mktemp -d /run/clone-install.XXXXXX)
      echo "Cloning $url (main, shallow) ..."
      git clone --quiet --depth 1 --branch main -- "$url" "$work/nix"

      export INSTALLER_LIVE=1
      export INSTALLER_SRC="$work/nix"
      export INSTALLER_REPO_URL="$url"
      exec bash "$work/nix/templates/installer/install.sh" "$@"
    '';
    meta.mainProgram = "clone-install";
  };
in
{
  inherit installer make-bundle clone-install tools;
}
