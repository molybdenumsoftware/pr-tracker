{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      treefmt.settings.global.excludes = [ ".sqlx/*" ];
      fileset = lib.fileset.unions [
        ../.sqlx
        ../migrations
      ];

      devshells.default = {
        env = lib.attrsToList {
          SQLX_OFFLINE = "true";
        };
        packages = [ pkgs.sqlx-cli ];
      };
    };
}
