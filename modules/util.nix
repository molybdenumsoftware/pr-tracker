{
  perSystem =
    { pkgs, ... }:
    {
      nci.projects.default.fileset = ../crates/util/migrations;
      treefmt.settings.global.excludes = [ "crates/util/migrations/*" ];
      devshells.default.commands = [
        {
          package = pkgs.writeShellApplication {
            name = "util-sqlx-prepare";
            runtimeInputs = [ pkgs.sqlx-cli ];
            text = "cargo run --package util --bin sqlx-prepare";
          };
          help = "Update query metadata. See https://github.com/launchbadge/sqlx/blob/v0.8.2/sqlx-cli/README.md#enable-building-in-offline-mode-with-query";
        }
        {
          package = pkgs.writeShellApplication {
            name = "util-db-repl";
            text = "cargo run --package util --bin db-repl";
          };
          help = "Start a psql repl connected to a database with migrations applied.";
        }
      ];
    };
}
