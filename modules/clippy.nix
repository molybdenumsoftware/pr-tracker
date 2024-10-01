{GITHUB_GRAPHQL_SCHEMA, ...}: {
  perSystem = {
    src,
    cargoArtifacts,
    craneLib,
    ...
  }: {
    checks.clippy = craneLib.cargoClippy {
      inherit src GITHUB_GRAPHQL_SCHEMA cargoArtifacts;
      cargoClippyExtraArgs = "--all-targets --all-features -- --deny warnings";
      pname = "pr-tracker";
      version = "unversioned";
    };
  };
}
