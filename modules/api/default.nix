{
  imports = [./nixos-module.nix];

  perSystem = {
    self',
    lib,
    pkgs,
    buildWorkspacePackage,
    ...
  }: {
    packages.api = buildWorkspacePackage {
      dir = "api";
      env = {
        POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
        POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
      };
    };

    checks."packages/api" = self'.packages.api;

    devshells.default.devshell.packages = [
      (pkgs.writeShellApplication {
        name = "util-run-api"; #<<< should this go in util instead? >>>
        # <<< runtimeInputs = [pkgs.sqlx-cli];
        text = "cargo run --package util --bin sqlx-prepare";
      })
    ];
  };
}
