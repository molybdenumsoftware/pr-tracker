{
  imports = [./nixos-module.nix];

  perSystem = {
    self',
    POSTGRESQL_INITDB_PATH,
    POSTGRESQL_POSTGRES_PATH,
    buildWorkspacePackage,
    ...
  }: {
    packages.api = buildWorkspacePackage {
      dir = "api";
      inherit POSTGRESQL_INITDB_PATH POSTGRESQL_POSTGRES_PATH;
    };

    checks."packages/api" = self'.packages.api;
  };
}
