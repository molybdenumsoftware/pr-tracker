{
  imports = [./nixos-module.nix];

  perSystem = {
    self',
    config,
    ...
  }: {
    nci.crates.pr-tracker-api.drvConfig.mkDerivation.meta.mainProgram = "pr-tracker-api";
    packages.api = config.nci.outputs.pr-tracker-api.packages.release;
    checks."packages/api" = self'.packages.api;
  };
}
