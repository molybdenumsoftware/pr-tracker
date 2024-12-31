{inputs, ...}: {
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
      crates = {
        pr-tracker-fetcher.drvConfig.mkDerivation.meta.mainProgram = "pr-tracker-fetcher";
        pr-tracker-fetcher-config.excludeFromProjectDocs = false;
      };
    };

    packages.fetcher = config.nci.outputs.pr-tracker-fetcher.packages.release;
    checks = {
      "packages/fetcher" = self'.packages.fetcher;
      "packages/fetcher/clippy" =
        (config.nci.outputs.pr-tracker-fetcher.clippy.extendModules {
          modules = [
            {
              rust-crane = {
                buildFlags = ["--all-targets" "--all-features"];
                depsDrv.mkDerivation.buildPhase = ":";
              };
            }
          ];
        })
        .config
        .public;
    };
  };
}
