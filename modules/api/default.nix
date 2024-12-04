{
  imports = [./nixos-module.nix];

  perSystem = {
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
  };
}
