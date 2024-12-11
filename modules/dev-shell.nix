{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.devshell.flakeModule
  ];
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
      interactive.pre-commit.text = lib.traceVal config.pre-commit.installationScript;
      # perSystem.devshells.<name>.devshell.startup.<name>.text

      packages = [pkgs.sqlx-cli pkgs.rust-analyzer] ++ devUtils;

        };
    };
  };
}
