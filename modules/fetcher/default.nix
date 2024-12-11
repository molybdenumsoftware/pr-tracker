{
  inputs,
  GITHUB_GRAPHQL_SCHEMA,
  ...
}: {
  imports = [./nixos-module.nix];

  _module.args.GITHUB_GRAPHQL_SCHEMA = "${inputs.github-graphql-schema}/schema.graphql";

  perSystem = {
    self',
    config,
    pkgs,
    lib,
    ...
  }: {
    nci.crates.pr-tracker-fetcher.drvConfig = {
      mkDerivation.meta.mainProgram = "pr-tracker-fetcher";
      env = {
        inherit GITHUB_GRAPHQL_SCHEMA;
        POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
        POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
        GIT = lib.getExe pkgs.git;
      };
    };

    packages.fetcher = config.nci.outputs.pr-tracker-fetcher.packages.release;
    checks."packages/fetcher" = self'.packages.fetcher;
  };
}
