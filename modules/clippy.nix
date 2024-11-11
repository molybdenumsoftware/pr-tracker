{GITHUB_GRAPHQL_SCHEMA, ...}: {
  perSystem = {
    src,
    cargoArtifacts,
    crane,
    ...
  }: {
    checks.clippy = crane.cargoClippy {
      inherit src GITHUB_GRAPHQL_SCHEMA cargoArtifacts;
      cargoClippyExtraArgs = "--all-targets --all-features -- --deny warnings";
      pname = "pr-tracker";
      version = "unversioned";
    };
  };
}
