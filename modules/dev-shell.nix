{
  inputs,
  lib,
  GITHUB_GRAPHQL_SCHEMA,
  ...
}: {
  imports = [
    inputs.devshell.flakeModule
  ];

  # <<< perSystem = {self', ...}: {
  # <<<   devshells.default = {
  # <<<     env = lib.attrsToList {
  # <<<       SQLX_OFFLINE = "true";
  # <<<       POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
  # <<<       POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
  # <<<       GIT = lib.getExe pkgs.git;
  # <<<     };
  # <<<     devshell = {
  # <<<       # Probably don't need these packages?
  # <<<       packages = [pkgs.sqlx-cli pkgs.rust-analyzer] ++ devUtils;
  # <<<     };
  # <<<   };
  # <<< };
}
