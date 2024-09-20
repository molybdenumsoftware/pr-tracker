{self, ...}: {
  flake.nixosModules.common = {
    pkgs,
    lib,
    ...
  }: {
    options._pr-tracker-packages = lib.mkOption {internal = true;};
    config._pr-tracker-packages = self.packages.${pkgs.system};
  };
}
