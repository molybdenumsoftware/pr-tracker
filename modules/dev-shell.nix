{
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem = {self', ...}: {
    devshells.default.devshell.packagesFrom = lib.attrValues self'.packages;
  };
}
