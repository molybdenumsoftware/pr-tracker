{
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem = {
    self',
    config,
    ...
  }: {
    devshells.default.devshell.packagesFrom = lib.attrValues self'.packages;
    checks.devshell = config.devShells.default;
  };
}
