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
  };
}
