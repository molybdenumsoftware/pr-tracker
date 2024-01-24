{
  buildWorkspacePackage,
  git,
  postgresql,
  GITHUB_GRAPHQL_SCHEMA,
}:
buildWorkspacePackage {
  inherit GITHUB_GRAPHQL_SCHEMA;
  dir = "fetcher";
  nativeCheckInputs = [git postgresql];
  cargoTestExtraArgs = "-- --skip 'github::test::pagination' --skip 'github::test::finite_pagination'";
}
