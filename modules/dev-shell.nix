{
  inputs,
  lib,
<<<<<<< Updated upstream
  inputs,
||||||| Stash base
  GITHUB_GRAPHQL_SCHEMA,
=======
>>>>>>> Stashed changes
  ...
}: {
  imports = [
    inputs.devshell.flakeModule
  ];
<<<<<<< Updated upstream
||||||| Stash base
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
=======
  perSystem = {
    pkgs,
    config,
    ...
  }: let
    devUtils = [
      (pkgs.writeShellApplication {
        name = "util-sqlx-prepare";
        runtimeInputs = [pkgs.sqlx-cli];
        text = "cargo run --package util --bin sqlx-prepare";
      })
>>>>>>> Stashed changes

<<<<<<< Updated upstream
  perSystem = {self', ...}: {
    devshells.default.devshell.packagesFrom = lib.attrValues self'.packages;
||||||| Stash base
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
=======
      (pkgs.writeShellApplication {
        name = "util-db-repl";
        text = "cargo run --package util --bin db-repl";
      })
    ];
  in {
    devshells.default = {
      env = lib.attrsToList {
        SQLX_OFFLINE = "true";
        POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
        POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
        GIT = lib.getExe pkgs.git;
      };
      devshell = {
        startup.pre-commit.text = config.pre-commit.installationScript;

        packages = [pkgs.sqlx-cli pkgs.rust-analyzer] ++ devUtils;
      };
    };
>>>>>>> Stashed changes
  };
}
