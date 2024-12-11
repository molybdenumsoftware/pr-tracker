{
  lib,
  GITHUB_GRAPHQL_SCHEMA,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    config,
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
      inherit GITHUB_GRAPHQL_SCHEMA;
      env = {
        POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
        POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
        GIT = lib.getExe pkgs.git;
      };
      inputsFrom = lib.attrValues self'.packages;
      packages = [pkgs.sqlx-cli] ++ devUtils;
      SQLX_OFFLINE = "true";
      shellHook = config.pre-commit.installationScript;
    };
  };
}
