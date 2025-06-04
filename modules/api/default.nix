{
  lib,
  api,
  psqlConnectionUriMdLink,
  environmentVariablesToMarkdown,
  ...
}:
{
  imports = [ ./nixos-module.nix ];

  _module.args.api.environmentVariables = lib.mapAttrs (name: v: v // { inherit name; }) {
    PR_TRACKER_API_DATABASE_URL = {
      description = # markdown
        "${psqlConnectionUriMdLink}.";
      rustType = "::std::string::String";
    };
    PR_TRACKER_API_PORT = {
      description =
        # markdown
        "Port to listen on.";
      rustType = "::core::primitive::u16";
    };
    PR_TRACKER_TRACING_FILTER = {
      description =
        # markdown
        ''
          Optional.
          Expected to deserialize into an [`EnvFilter`](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/filter/struct.EnvFilter.html).
        '';
      # Note: ideally we'd use `::core::option::Option`, but cannot because
      # confique's derive macro seems not to support it.
      rustType = "Option<TracingFilter>";
    };
  };

  perSystem =
    {
      pkgs,
      self',
      config,
      writeEnvironmentStructFile,
      ...
    }:
    {
      chapters.api = {
        title = "API";
        drv = pkgs.writeTextFile {
          name = "api.md";
          text = ''
            ## Environment Variables

            ${environmentVariablesToMarkdown api.environmentVariables}
          '';
        };
      };

      nci = {
        crates = {
          pr-tracker-api.drvConfig = {
            mkDerivation.meta.mainProgram = "pr-tracker-api";
            env.api_config_snippet = writeEnvironmentStructFile "api" api.environmentVariables;
          };
        };
      };
      packages.api = config.nci.outputs.pr-tracker-api.packages.release;
      checks = {
        "packages/api" = self'.packages.api;
        "packages/api/clippy" = config.nci.outputs.pr-tracker-api.clippy;
      };
    };
}
