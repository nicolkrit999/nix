flake:
{
  mkNixos = modules: flake.nixosConfigurations.template-host-minimal.extendModules { inherit modules; };
  hmOf = c: c.config.home-manager.users.${c.config.myconfig.constants.user};
}
