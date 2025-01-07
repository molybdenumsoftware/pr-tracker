{
  imports = [./nixos-module.nix];

  perSystem = {
    self',
    config,
    ...
  }: {
    nci = {
      crates = {
        pr-tracker-api.drvConfig.mkDerivation.meta.mainProgram = "pr-tracker-api";
        pr-tracker-api-config.excludeFromProjectDocs = false;
      };
      projects.default.fileset = ../../crates/api-config/PORT.md;
    };
    packages.api = config.nci.outputs.pr-tracker-api.packages.release;
    checks = {
      "packages/api" = self'.packages.api;
      "packages/api/clippy" =
        (config.nci.outputs.pr-tracker-api.clippy.extendModules {
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
