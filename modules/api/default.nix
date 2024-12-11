{
  imports = [./nixos-module.nix];

  perSystem = {
    self',
    lib,
    config,
    pkgs,
    ...
  }: {
    nci.crates.pr-tracker-api.drvConfig.mkDerivation.meta.mainProgram = "pr-tracker-api";
    packages.api = config.nci.outputs.pr-tracker-api.packages.release;
    nci.crates.pr-tracker-api.drvConfig.env = {
      POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
      POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
    };
    checks."packages/api" = self'.packages.api;
  };
}
