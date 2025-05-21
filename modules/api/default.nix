{ lib, ... }:
{
  imports = [ ./nixos-module.nix ];

  perSystem =
    {
      self',
      config,
      pkgs,
      ...
    }:

    let
      envConfig = [
        {
          name = "PR_TRACKER_API_DATABASE_URL";
          descriptionMd =
            # markdown
            "[PostgreSQL connection URI](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING-URIS).";
          rustType = "String";
        }
        {
          name = "PR_TRACKER_API_PORT";
          descriptionMd =
            # markdown
            "Port to listen on.";
          rustType = "u16";
        }
        {
          name = "PR_TRACKER_TRACING_FILTER";
          descriptionMd =
            # markdown
            "Expected to deserialize into an [`EnvFilter`](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/filter/struct.EnvFilter.html).";
          rustType = "Option<TracingFilter>"; # <<< TODO use absolute path here instead >>>
        }
      ];

      # <<< #[doc = include_str!("../../DATABASE_URL.md")]
      # <<< #[config(env = "PR_TRACKER_API_DATABASE_URL")]
      # <<< pub PR_TRACKER_API_DATABASE_URL: String,
      # <<< #[config(env = "PR_TRACKER_API_PORT")]
      # <<< #[doc = include_str!("../PORT.md")]
      # <<< pub PR_TRACKER_API_PORT: u16,
      # <<< #[config(env = "PR_TRACKER_TRACING_FILTER")]
      # <<< #[doc = include_str!("../TRACING_FILTER.md")]
      fields = lib.pipe envConfig [
        (map (envSpec: ''
          /// ${envSpec.descriptionMd}
          #[config(env = "${envSpec.name}")]
          pub ${envSpec.name}: ${envSpec.rustType},
        ''))
        lib.concatLines
      ];
    in
    {
      nci = {
        crates = {
          pr-tracker-api.drvConfig = {
            env.api_config_snippet = pkgs.writeTextFile {
              name = "api-config-env-struct.rs";
              text =
                # rust
                ''
                  #[derive(Debug, Config)]
                  pub struct Environment {
                  ${fields}
                  }
                '';
            };
            mkDerivation.meta.mainProgram = "pr-tracker-api";
          };
          pr-tracker-api-config.includeInProjectDocs = true;
        };
      };
      packages.api = config.nci.outputs.pr-tracker-api.packages.release;
      checks = {
        "packages/api" = self'.packages.api;
        "packages/api/clippy" = config.nci.outputs.pr-tracker-api.clippy;
      };
    };
}
