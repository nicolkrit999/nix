{ delib
, pkgs
, lib
, moduleSystem
, ...
}:
delib.module {
  name = "krit.programs.ranger";
  options = delib.singleEnableOption false;

  myconfig.ifEnabled.programs.ranger.enable = true;

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      isNixOS = moduleSystem == "nixos";
      terminal = myconfig.constants.terminal.name;
      opener = if moduleSystem == "darwin" then "open" else "xdg-open";
    in
    {
      home.packages = [ pkgs.fzf ];

      programs.ranger = {
        rifle = [
          {
            condition = "flag f";
            command = ''${opener} "$1"'';
          }
          {
            condition = "else";
            command = ''${opener} "$1"'';
          }
        ];

        mappings = {
          e = "edit";
          ec = "compress"; # Archive selected files using ranger-archives
          ex = "extract"; # Extract selected archive using ranger-archives
          b = "fzm"; # Fast directory jumping using fzf-marks
          "." = "set show_hidden!"; # Toggle hidden files on/off by pressing "."
        };

        settings = {
          wrap_scroll = true; # Wrap around at the ends of a list
          draw_borders = true; # Draws borders between columns
          w3m_delay = 0; # Instant rendering for w3m previews
        };

        extraConfig = ''
          default_linemode devicons2
        '';

        plugins = [
          {
            name = "ranger-archives";
            src = pkgs.fetchFromGitHub {
              owner = "maximtrp";
              repo = "ranger-archives";
              rev = "b4e136b24fdca7670e0c6105fb496e5df356ef25";
              hash = "sha256-QJu5G2AYtwcaE355yhiG4wxGFMQvmBWvaPQGLsi5x9Q=";
            };
          }
          {
            name = "ranger-devicons2";
            src = pkgs.fetchFromGitHub {
              owner = "cdump";
              repo = "ranger-devicons2";
              rev = "94bdcc19218681debb252475fd9d11cfd274d9b1";
              hash = "sha256-aJCIoDfzmOnzMLlbOe+dy6129n5Dc4OrefhHnPsgI8k=";
            };
          }
          {
            name = "ranger_tmux"; # tmux integration
            src = pkgs.fetchFromGitHub {
              owner = "joouha";
              repo = "ranger_tmux";
              rev = "05ba5ddf2ce5659a90aa0ada70eb1078470d972a";
              hash = "sha256-KCBOPwhG4U/k2a/Dp/+fZeetFz/PW9424zi3NlLsDj0=";
            };
          }
          {
            name = "ranger_udisk_menu"; # imported by commands.py below
            src = pkgs.fetchFromGitHub {
              owner = "SL-RU";
              repo = "ranger_udisk_menu";
              rev = "d676b7d5406d804ea4ceb894768674a740d95ebb";
              hash = "sha256-AzuWe6KXXusUfn8UABRq93/tvtiUB1OIlxGiljNuc2g=";
            };
          }
          {
            name = "fzf-marks"; # provides the fzm command mapped to b
            src = pkgs.fetchFromGitHub {
              owner = "laggardkernel";
              repo = "ranger-fzf-marks";
              rev = "1d0c42cd4fd01c73bcb02e3cebcec22987b8a46d";
              hash = "sha256-6Li/vLdtKItCpLwa+wX/C2FO+AW1hWPcKy/sx7KSZrM=";
            };
          }
        ];
      };

      home.file.".config/ranger/commands.py".text = "from plugins.ranger_udisk_menu.mounter import mount";

      xdg.desktopEntries.ranger = lib.mkIf isNixOS {
        name = "Ranger";
        genericName = "File Manager";
        exec = "${pkgs.${terminal}}/bin/${terminal} --class ranger -e ${pkgs.ranger}/bin/ranger";
        terminal = false;
        categories = [
          "System"
          "FileTools"
          "FileManager"
        ];
        mimeType = [ "inode/directory" ];
      };
    };
}
