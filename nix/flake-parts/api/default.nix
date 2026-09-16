{
  environmentVariablesToMarkdown,
  ...
}:
{

  perSystem =
    {
      pkgs,
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

              ${environmentVariablesToMarkdown pkgs.pr-tracker.passthru.configVars.api}
            '';
        };
      };

      files.file."crates/api/config_snippet.rs".source =
        writeEnvironmentStructFile "api" pkgs.pr-tracker.passthru.configVars.api;

    };
}
