{
  lib,
  rustPlatform,
  gitMinimal,
  postgresql,
  octokit-graphql-schema,
  clippy,
}:
let
  projectRoot = ../../..;

  configVars = {
    fetcher = lib.mapAttrs (name: v: v // { inherit name; }) {
      PR_TRACKER_FETCHER_DATABASE_URL = {
        description = "PostgreSQL connection URI";
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

    api = lib.mapAttrs (name: v: v // { inherit name; }) {
      PR_TRACKER_API_DATABASE_URL = {
        description = # markdown
          "PostgreSQL connection URI";
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
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "pr-tracker";
  inherit ((lib.importTOML (projectRoot + "/Cargo.toml")).workspace.package) version;
  src = lib.fileset.toSource {
    root = projectRoot;
    fileset = lib.fileset.unions [
      (lib.fileset.fileFilter (
        file:
        lib.elem file.name [
          "Cargo.toml"
          "Cargo.lock"
        ]
      ) projectRoot)
      (lib.fileset.fileFilter (
        file:
        lib.any file.hasExt [
          "rs"
          "graphql"
          "sql"
        ]
      ) projectRoot)
      (projectRoot + "/.sqlx")
    ];
  };
  cargoLock.lockFile = projectRoot + "/Cargo.lock";
  buildType = "debug";
  passthru = {
    env = {
      CARGO_BUILD_WARNINGS = "deny";
      GIT = lib.getExe gitMinimal;
      POSTGRESQL_INITDB = lib.getExe' postgresql "initdb";
      POSTGRESQL_POSTGRES = lib.getExe' postgresql "postgres";
      OCTOKIT_GRAPHQL_SCHEMA = "${octokit-graphql-schema}/schema.graphql";
    };
    inherit configVars;
  };
  env = finalAttrs.passthru.env // {
    CARGO_BUILD_WARNINGS = "deny";
  };
  nativeCheckInputs = [ clippy ];
  preCheck = ''
    cargo clippy --all-targets --all-features
  '';
})
