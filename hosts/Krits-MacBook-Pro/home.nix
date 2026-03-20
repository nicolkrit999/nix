{ delib
, inputs
, pkgs
, pkgs-unstable
, lib
, ...
}:
delib.host {
  name = "Krits-MacBook-Pro";

  home = {
    home.stateVersion = "25.11";

    home.packages =
      (with pkgs; [
        vscode
        ranger
        killall
        nix-search-cli
        ripgrep
        unzip
        zip
        zlib
        wget
      ])
      ++ (with pkgs-unstable; [
      ]);

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    home.activation = {
      createHostDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/Pictures/wallpapers || true
        mkdir -p $HOME/momentary || true
        mkdir -p $HOME/.config/portainer-mcp || true
      '';
    };

    # -----------------------------------------------------------------------
    # 🔐 HOST-SPECIFIC GIT SSH SIGNING
    # -----------------------------------------------------------------------
    programs.git = {
      signing = lib.mkForce {
        key = "/Users/krit/.ssh/id_github";
        signByDefault = true;
      };
      settings = {
        gpg.format = lib.mkForce "ssh";
        user.signingKey = lib.mkForce "/Users/krit/.ssh/id_github";
        commit.gpgSign = lib.mkForce true;
        gpg.ssh.allowedSignersFile = lib.mkForce "/Users/krit/.ssh/allowed_signers";
      };

      includes = [
        {
          condition = "gitdir:~/school-workspace/**";
          contents = {
            user.email = "kritpio.nicol@student.supsi.ch";
            user.name = "Krit Pio Nicol-University";
            user.signingkey = "/Users/krit/.ssh/id_school";
          };
        }
      ];
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "github.com" = {
          identityFile = "/Users/krit/.ssh/id_github";
        };
        "nicol-nas 192.168.1.98 ssh.nicolkrit.ch" = {
          identityFile = "/Users/krit/.ssh/id_github";
          identitiesOnly = true;
          user = "krit";
        };
        "gitlab-edu.supsi.ch" = {
          hostname = "gitlab-edu.supsi.ch";
          identityFile = "/Users/krit/.ssh/id_school";
          identitiesOnly = true;
        };
        "github-school" = {
          hostname = "github.com";
          identityFile = "/Users/krit/.ssh/id_school";
          identitiesOnly = true;
        };
      };
    };

    home.file.".ssh/allowed_signers".text = ''
      githubgitlabmain.hu5b7@passfwd.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO4fJZtoawnvuR2D/CAk7fBrioEyhyagheH4RtTaf8gD
      kritpio.nicol@student.supsi.ch ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBRKQLjixO72qgAc64gzJwsmOdoNQs+KkQg8GewHnm66
    '';

    programs.gpg.enable = lib.mkForce false;
    services.gpg-agent.enable = lib.mkForce false;
  };
}
