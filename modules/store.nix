{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      treefmt.settings.global.excludes = [ ".sqlx/*" ];

      devshells.default = {
        env = lib.attrsToList {
          SQLX_OFFLINE = "true";
        };
        packages = [ pkgs.sqlx-cli ];
      };
    };
}
