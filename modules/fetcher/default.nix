{
  lib,
  inputs,
  fetcher,
  psqlConnectionUriMdLink,
  environmentVariablesToMarkdown,
  ...
}:
{

  flake-file.inputs.github-graphql-schema = {
    url = "github:octokit/graphql-schema";
    flake = false;
  };

  _module.args.fetcher.environmentVariables = lib.mapAttrs (name: v: v // { inherit name; }) {
    PR_TRACKER_FETCHER_DATABASE_URL = {
      description = "${psqlConnectionUriMdLink}.";
      rustType = "::std::string::String";
    };
    PR_TRACKER_FETCHER_GITHUB_TOKEN = {
      description =
        # markdown
        "GitHub API token with read access to the repository's pull requests.";
      rustType = "::std::string::String";
    };
    PR_TRACKER_FETCHER_GITHUB_REPO_OWNER = {
      description =
        # markdown
        "GitHub repository owner.";
      rustType = "::std::string::String";
    };
    PR_TRACKER_FETCHER_GITHUB_REPO_NAME = {
      description =
        # markdown
        "GitHub repository name.";
      rustType = "::std::string::String";
    };
    PR_TRACKER_FETCHER_CACHE_DIR = {
      description =
        # markdown
        "Cache directory (for repository clone).";
      rustType = "::camino::Utf8PathBuf";
    };
    PR_TRACKER_FETCHER_BRANCH_PATTERNS = {
      description =
        # markdown
        ''
          JSON array of strings representing branch patterns to track.

          - `?` matches a single occurrence of any character.
          - `*` matches zero or more occurrences of any character.

          No escape characters.
        '';
      rustType = "::std::string::String";
    };
  };

  perSystem =
    psArgs@{
      self',
      pkgs,
      writeEnvironmentStructFile,
      ...
    }:
    {
      fileset = ../../crates/fetcher/src/graphql;

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

              ${environmentVariablesToMarkdown fetcher.environmentVariables}
            '';
        };
      };

      env = {
        GITHUB_GRAPHQL_SCHEMA = "${inputs.github-graphql-schema}/schema.graphql";
        GIT = lib.getExe pkgs.gitMinimal;
      };

      files.file."crates/fetcher/config_snippet.rs".source =
        writeEnvironmentStructFile "fetcher" fetcher.environmentVariables;

      packages.fetcher = lib.recursiveUpdate psArgs.config.package {
        meta.mainProgram = "pr-tracker-fetcher";
      };
    };
}
