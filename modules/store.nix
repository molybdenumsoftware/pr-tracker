{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      treefmt.settings.global.excludes = [
        "crates/store/.sqlx/*"
        "crates/store/migrations/*"
      ];
      fileset = lib.fileset.unions [
        ../crates/store/.sqlx
        ../crates/store/migrations
      ];

      devshells.default = {
        env = lib.attrsToList {
          SQLX_OFFLINE = "true";
        };
        packages = [ pkgs.sqlx-cli ];
        commands = [
          {
            package = pkgs.writeShellApplication {
              name = "util-sqlx-prepare";
              runtimeInputs = [ pkgs.sqlx-cli ];
              text = "exec cargo run --package pr-tracker-store --bin sqlx-prepare";
            };
            help = "Update query metadata. See https://github.com/launchbadge/sqlx/blob/v0.8.2/sqlx-cli/README.md#enable-building-in-offline-mode-with-query";
          }
        ];
      };

    };
}
