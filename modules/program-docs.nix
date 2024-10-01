{GITHUB_GRAPHQL_SCHEMA, ...}: {
  perSystem = {
    craneLib,
    src,
    cargoArtifacts,
    self',
    ...
  }: {
    packages.program-docs = craneLib.cargoDoc {
      inherit src cargoArtifacts GITHUB_GRAPHQL_SCHEMA;

      pname = "pr-tracker-program-docs";
      version = "unversioned";

      cargoDocExtraArgs = "--package pr-tracker-fetcher-config --package pr-tracker-api-config --no-deps";
    };

    checks."packages/program-docs" = self'.packages.program-docs;
  };
}
