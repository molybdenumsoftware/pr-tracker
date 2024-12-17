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
    buildWorkspacePackage,
    ...
  }: {
    packages.fetcher = buildWorkspacePackage {
      inherit GITHUB_GRAPHQL_SCHEMA;
      env = {
        POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
        POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
        GIT = lib.getExe pkgs.git;
      };

      dir = "fetcher";
    };

    devshells.default.env = lib.attrsToList {
      inherit GITHUB_GRAPHQL_SCHEMA;
      GIT = lib.getExe pkgs.git;
    };

    checks."packages/fetcher" = self'.packages.fetcher;
  };
}
