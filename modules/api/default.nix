{
  lib,
  api,
  psqlConnectionUriMdLink,
  environmentVariablesToMarkdown,
  ...
}:
{

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
    psArgs@{
      pkgs,
      self',
      writeEnvironmentStructFile,
      ...
    }:
    {
      chapters.api = {
        title = "API";
        drv = pkgs.writeTextFile {
          name = "api.md";
          text =
            # markdown
            ''
              Takes no arguments.

              - `/openapi.json`
              - `/` redirects to API documentation

              ## Environment Variables

              Reads the following environment variables.

              ${environmentVariablesToMarkdown api.environmentVariables}
            '';
        };
      };

      defaultCrateOverrides.pr-tracker-api = attrs: {
        meta.mainProgram = "pr-tracker-api";
        env.api_config_snippet = writeEnvironmentStructFile "api" api.environmentVariables;
      };
      packages.api = psArgs.config.crate2nix.workspace.workspaceMembers.pr-tracker-api.build;
      checks = {
        "packages/api" = self'.packages.api;
      };
    };
}
