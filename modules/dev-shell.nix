{
  lib,
  GITHUB_GRAPHQL_SCHEMA,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    POSTGRESQL_INITDB_PATH,
    POSTGRESQL_POSTGRES_PATH,
    ...
  }: let
    devUtils = [
      (pkgs.writeShellApplication {
        name = "util-sqlx-prepare";
        runtimeInputs = [pkgs.sqlx-cli];
        text = "cargo run --package util --bin sqlx-prepare";
      })

      (pkgs.writeShellApplication {
        name = "util-db-repl";
        text = "cargo run --package util --bin db-repl";
      })
    ];
  in {
    devShells.default = pkgs.mkShell {
      inherit GITHUB_GRAPHQL_SCHEMA POSTGRESQL_INITDB_PATH POSTGRESQL_POSTGRES_PATH;
      GIT_PATH = lib.getExe pkgs.git;
      inputsFrom = lib.attrValues self'.packages;
      packages = [pkgs.sqlx-cli] ++ devUtils;
      SQLX_OFFLINE = "true";
    };
  };
}
