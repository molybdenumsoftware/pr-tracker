{
  imports = [./nixos-module.nix];

  perSystem = {
    self',
    config,
    pkgs,
    ...
  }: {
    nci.crates.pr-tracker-api = {
      drvConfig = {
        mkDerivation = {
          nativeCheckInputs = [pkgs.postgresql];
        };
      };
    };

    packages.api = config.nci.outputs.pr-tracker-api.packages.release;
    checks."packages/api" = self'.packages.api;
  };
}
