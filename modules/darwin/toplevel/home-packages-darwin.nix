{ delib
, pkgs
, lib
, config
, ...
}:
delib.module {
  name = "home-packages";
  options = delib.singleEnableOption true;

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      getPkg = name: if builtins.hasAttr name pkgs then pkgs.${name} else null;

      editorName =
        let
          e = myconfig.constants.editor;
        in
        if e == "nvim" then "neovim" else e;

      roles = {
        terminal = myconfig.constants.terminal.name;
        browser = myconfig.constants.browser;
        fileManager = myconfig.constants.fileManager;
        editor = editorName;
      };

      isProgramEnabled = name:
        lib.attrByPath [ "programs" name "enable" ] false config
        || lib.attrByPath [ "home-manager" "users" myconfig.constants.user "programs" name "enable" ] false config;

      # browser = "" opts a host out of the browser package (no package, no warning)
      activeRoles = lib.filterAttrs (role: name: !(role == "browser" && name == "")) roles;
    in
    {
      environment.systemPackages = lib.concatMap
        (name:
          let
            pkg = getPkg name;
          in
          lib.optional (pkg != null && !isProgramEnabled name) pkg)
        (lib.attrValues activeRoles);

      warnings = lib.mapAttrsToList
        (role: name:
          "home-packages: constants ${role} = \"${name}\" is not a package in pkgs; nothing is installed for it.")
        (lib.filterAttrs (_: name: getPkg name == null) activeRoles);
    };
}
