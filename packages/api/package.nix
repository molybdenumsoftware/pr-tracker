{
  buildWorkspacePackage,
  postgresql,
}:
buildWorkspacePackage {
  dir = "api";
  nativeCheckInputs = [postgresql];
}
