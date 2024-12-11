{
  imports = [./nixos-module.nix];

  perSystem = {
    self',
    lib,
    config,
    pkgs,
    ...
  }: {
    nci.crates.pr-tracker-api.drvConfig.mkDerivation.nativeCheckInputs = [pkgs.postgresql];
    packages.api = config.nci.outputs.pr-tracker-api.packages.release;
      # <<< env = {
      # <<<   POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
      # <<<   POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
      # <<< };
    checks."packages/api" = self'.packages.api;
  };
}
