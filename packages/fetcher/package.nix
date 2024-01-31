{
  buildWorkspacePackage,
  git,
  lib,
  makeWrapper,
  postgresql,
  GITHUB_GRAPHQL_SCHEMA,
}: let
  inherit
    (lib)
    makeBinPath
    ;
in
  buildWorkspacePackage {
    inherit GITHUB_GRAPHQL_SCHEMA;
    dir = "fetcher";
    nativeCheckInputs = [git postgresql];
    nativeBuildInputs = [makeWrapper];
    cargoTestExtraArgs = "-- --skip 'github::test::pagination' --skip 'github::test::finite_pagination'";
    postInstall = ''
      wrapProgram $out/bin/pr-tracker-fetcher --prefix PATH ":" ${makeBinPath [git]}
    '';
  }
