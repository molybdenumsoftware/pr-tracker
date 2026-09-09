{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      defaultCrateOverrides.db-context = attrs: {
        env = {
          POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
          POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
        };
      };
    };
}
