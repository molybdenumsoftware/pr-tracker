{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      treefmt.settings.global.excludes = [ ".sqlx/*" ];
      fileset = ../.sqlx;

      devshells.default = {
        env = lib.attrsToList {
          SQLX_OFFLINE = "true";
        };
        packages = [ pkgs.sqlx-cli ];
      };
    };
}
