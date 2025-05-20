{ lib, ... }:
{
  imports = [ ./nixos-module.nix ];

  perSystem =
    {
      self',
      config,
      ...
    }:
    {
      nci = {
        crates = {
          pr-tracker-api.drvConfig.mkDerivation.meta.mainProgram = "pr-tracker-api";
          pr-tracker-api-config.includeInProjectDocs = true;
        };
        projects.default.fileset = lib.fileset.unions [
          ../../crates/api-config/PORT.md
          ../../crates/api-config/TRACING_FILTER.md
        ];
      };
      packages.api = config.nci.outputs.pr-tracker-api.packages.release;
      checks = {
        "packages/api" = self'.packages.api;
        "packages/api/clippy" = config.nci.outputs.pr-tracker-api.clippy;
      };
    };
}
