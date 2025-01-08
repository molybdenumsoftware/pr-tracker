{ inputs, ... }:
{
  imports = [ ./nixos-module.nix ];

  perSystem =
    {
      self',
      config,
      pkgs,
      lib,
      ...
    }:
    {
      nci = {
        projects.default = {
          drvConfig.env = {
            GITHUB_GRAPHQL_SCHEMA = "${inputs.github-graphql-schema}/schema.graphql";
            GIT = lib.getExe pkgs.git;
          };
          fileset = lib.fileset.unions [
            ../../crates/fetcher-config/BRANCH_PATTERNS.md
            ../../crates/fetcher-config/GITHUB_TOKEN.md
            ../../crates/fetcher-config/GITHUB_REPO_OWNER.md
            ../../crates/fetcher-config/GITHUB_REPO_NAME.md
          ];
        };
        crates = {
          pr-tracker-fetcher.drvConfig.mkDerivation.meta.mainProgram = "pr-tracker-fetcher";
          pr-tracker-fetcher-config.includeInProjectDocs = true;
        };
      };

      packages.fetcher = config.nci.outputs.pr-tracker-fetcher.packages.release;
      checks = {
        "packages/fetcher" = self'.packages.fetcher;
        "packages/fetcher/clippy" = config.nci.outputs.pr-tracker-fetcher.clippy;
      };
    };
}
