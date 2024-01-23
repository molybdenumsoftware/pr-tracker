{
  buildWorkspacePackage,
  git,
  postgresql,
}:
buildWorkspacePackage {
  dir = "fetcher";
  nativeCheckInputs = [git postgresql];
  cargoTestExtraArgs = "-- --skip 'github::test::pagination' --skip 'github::test::finite_pagination'";
}
