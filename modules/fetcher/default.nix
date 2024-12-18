{
  inputs,
  ...
}: {
  imports = [./nixos-module.nix];

  perSystem = {
    self',
    config,
    pkgs,
    lib,
    ...
  }: {
    nci = {
      projects.default.drvConfig.env = {
        GITHUB_GRAPHQL_SCHEMA = "${inputs.github-graphql-schema}/schema.graphql";
        GIT = lib.getExe pkgs.git;
      };
      crates.pr-tracker-fetcher.drvConfig.mkDerivation.meta.mainProgram = "pr-tracker-fetcher";
    };

    packages.fetcher = config.nci.outputs.pr-tracker-fetcher.packages.release;
    checks."packages/fetcher" = self'.packages.fetcher;
  };
}
