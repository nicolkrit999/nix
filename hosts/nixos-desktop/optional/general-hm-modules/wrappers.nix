{ pkgs, vars, ... }:
let
  policyRoot = "/home/${vars.user}/.librewolf-policyroot";
  wrapper = pkgs.writeShellScriptBin "librewolf" ''
    set -eu
    export MOZ_APP_DISTRIBUTION="${policyRoot}"

    # loud debug so you can see it in terminal launches
    echo "MOZ_APP_DISTRIBUTION=$MOZ_APP_DISTRIBUTION" >&2

    exec ${pkgs.librewolf}/bin/librewolf "$@"
  '';
in {
  home.packages = [ wrapper pkgs.librewolf ];

  home.file.".librewolf-policyroot/distribution/policies.json".text =
    builtins.toJSON {
      policies = {
        # Put something unmistakable to verify override works
        SupportMenu = {
          Title = "HM POLICY ACTIVE";
          URL = "https://example.com";
        };

        # Your real needed policies
        Cookies = {
          Allow = [
            "https://pocket-id.nicolkrit.ch"
            "https://nicolkrit.cloudflareaccess.com"
          ];
        };

        Preferences = {
          "network.cookie.cookieBehavior" = {
            Value = 0;
            Status = "locked";
          };
          "network.trr.mode" = {
            Value = 5;
            Status = "locked";
          };
        };
      };
    };
}
