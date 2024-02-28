{
  cargoDoc,
  src,
  cargoArtifacts,
  GITHUB_GRAPHQL_SCHEMA,
}:
cargoDoc {
  inherit src cargoArtifacts GITHUB_GRAPHQL_SCHEMA;

  pname = "pr-tracker-docs";
  version = "unversioned";

  cargoDocExtraArgs = "--package pr-tracker-fetcher-config --package pr-tracker-api-config --no-deps";
}
