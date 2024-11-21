{
  lib,
  inputs,
  GITHUB_GRAPHQL_SCHEMA,
  ...
}: {
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem = {
    pkgs,
    self',
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
        inherit GITHUB_GRAPHQL_SCHEMA;
        SQLX_OFFLINE = "true";
      };
      devshell.packagesFrom = lib.attrValues self'.packages;
      devshell.packages = [pkgs.sqlx-cli] ++ devUtils;
    };
  };
}
