{
  environmentVariablesToMarkdown,
  config,
  ...
}:
{

  flake-file.inputs.octokit-graphql-schema = {
    url = "github:octokit/graphql-schema";
    flake = false;
  };

  perSystem =
    {
      pkgs,
      writeEnvironmentStructFile,
      ...
    }:
    {

      chapters.fetcher = {
        title = "Fetcher";
        drv = pkgs.writeTextFile {
          name = "fetcher.md";
          text =
            # markdown
            ''
              Intended to be periodically executed.
              Takes no arguments.

              ## Environment Variables

              Reads the following environment variables.

              ${environmentVariablesToMarkdown pkgs.pr-tracker.passthru.configVars.fetcher}
            '';
        };
      };

      files.file."crates/fetcher/config_snippet.rs".source =
        writeEnvironmentStructFile "fetcher" pkgs.pr-tracker.passthru.configVars.fetcher;

    };

  flake.nixosModules.fetcher = config.projectRoot + "/nix/nixos/fetcher";
}
