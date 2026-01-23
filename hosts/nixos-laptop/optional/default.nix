
{ lib, vars, ... }:
let
  genPath = ./general-hm-modules;
  hostPath = ./host-hm-modules;
  genExists = builtins.pathExists genPath;
  hostExists = builtins.pathExists hostPath;

  # Define the configuration logic here so we can reuse it
  finalConfig = {
    imports = [
      #./dev-environments
      ./host-packages
      ./various
    ];

    home-manager.users.${vars.user} = {
      imports =
        [ ]
        ++ lib.optional genExists ./general-hm-modules
        ++ lib.optional hostExists ./host-hm-modules;
    };
  };
in
# 🟢 Logic: Check if BOTH exist.
# If YES -> Print the success message and return config.
# If NO  -> Just return config silently.
if genExists && hostExists then
  builtins.trace "✅ Success: Both General and Host HM modules detected." finalConfig
else
  finalConfig
