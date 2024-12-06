{
  inputs,
  GITHUB_GRAPHQL_SCHEMA,
  ...
}: {
  imports = [./nixos-module.nix];

  _module.args.GITHUB_GRAPHQL_SCHEMA = "${inputs.github-graphql-schema}/schema.graphql";

  perSystem = {
    self',
    pkgs,
    lib,
    POSTGRESQL_INITDB_PATH,
    POSTGRESQL_POSTGRES_PATH,
    buildWorkspacePackage,
    ...
  }: {
    packages.fetcher = buildWorkspacePackage {
      inherit GITHUB_GRAPHQL_SCHEMA POSTGRESQL_INITDB_PATH POSTGRESQL_POSTGRES_PATH;
      GIT_PATH = lib.getExe pkgs.git;

      dir = "fetcher";
      nativeBuildInputs = with pkgs; [makeWrapper];
    };

    checks."packages/fetcher" = self'.packages.fetcher;
  };
}
