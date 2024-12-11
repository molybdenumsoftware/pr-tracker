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
    ...
  }: {
    checks.clippy = crane.cargoClippy {
      inherit
        src
        GITHUB_GRAPHQL_SCHEMA
        cargoArtifacts
        ;
      env = {
        POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
        POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
        GIT = lib.getExe pkgs.git;
      };
      cargoClippyExtraArgs = "--all-targets --all-features -- --deny warnings";
      pname = "pr-tracker";
      version = "unversioned";
    };
  };
}
