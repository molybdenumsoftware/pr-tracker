{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      env = {
        POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
        POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
      };
    };
}
