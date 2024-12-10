{GITHUB_GRAPHQL_SCHEMA, ...}: {
  perSystem = {
    src,
    cargoArtifacts,
    crane,
    GIT_PATH,
    POSTGRESQL_INITDB_PATH,
    POSTGRESQL_POSTGRES_PATH,
    ...
  }: {
    checks.clippy = crane.cargoClippy {
      inherit
        src
        GITHUB_GRAPHQL_SCHEMA
        GIT_PATH
        POSTGRESQL_INITDB_PATH
        POSTGRESQL_POSTGRES_PATH
        cargoArtifacts
        ;
      cargoClippyExtraArgs = "--all-targets --all-features -- --deny warnings";
      pname = "pr-tracker";
      version = "unversioned";
    };
  };
}
