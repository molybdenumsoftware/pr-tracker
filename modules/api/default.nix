{
  imports = [./nixos-module.nix];

  perSystem = {
    self',
    pkgs,
    lib,
    buildWorkspacePackage,
    ...
  }: {
    packages.api = buildWorkspacePackage {
      dir = "api";
      POSTGRESQL_BIN_PATH = lib.getBin pkgs.postgresql;
    };

    checks."packages/api" = self'.packages.api;
  };
}
