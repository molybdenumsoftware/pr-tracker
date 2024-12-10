{
  GITHUB_GRAPHQL_SCHEMA,
  lib,
  ...
}: {
  perSystem = {
    pkgs,
    src,
    cargoArtifacts,
    crane,
    POSTGRESQL_INITDB_PATH,
    POSTGRESQL_POSTGRES_PATH,
    ...
  }: {
    checks.clippy = crane.cargoClippy {
      inherit
        src
        GITHUB_GRAPHQL_SCHEMA
        POSTGRESQL_INITDB_PATH
        POSTGRESQL_POSTGRES_PATH
        cargoArtifacts
        ;
      GIT_PATH = lib.getExe pkgs.git;
      cargoClippyExtraArgs = "--all-targets --all-features -- --deny warnings";
      pname = "pr-tracker";
      version = "unversioned";
    };
  };
}
