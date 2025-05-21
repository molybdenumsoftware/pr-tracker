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
          pr-tracker-api.drvConfig = {
            env.api_config_snippet =
              # rust
              ''
                #[derive(Debug, Config)]
                pub struct Environment {
                  #[doc = include_str!("../../DATABASE_URL.md")]
                  #[config(env = "PR_TRACKER_API_DATABASE_URL")]
                  pub PR_TRACKER_API_DATABASE_URL: String,
                  #[config(env = "PR_TRACKER_API_PORT")]
                  #[doc = include_str!("../PORT.md")]
                  pub PR_TRACKER_API_PORT: u16,
                  #[config(env = "PR_TRACKER_TRACING_FILTER")]
                  #[doc = include_str!("../TRACING_FILTER.md")]
                  pub PR_TRACKER_TRACING_FILTER: Option<TracingFilter>,
                }
              '';
            mkDerivation.meta.mainProgram = "pr-tracker-api";
          };
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
