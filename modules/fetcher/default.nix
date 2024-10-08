{GITHUB_GRAPHQL_SCHEMA, ...}: {
  imports = [./nixos-module.nix];

  perSystem = {
    self',
    pkgs,
    lib,
    buildWorkspacePackage,
    ...
  }: {
    packages.fetcher = buildWorkspacePackage {
      inherit GITHUB_GRAPHQL_SCHEMA;

      dir = "fetcher";
      nativeCheckInputs = with pkgs; [git postgresql];
      nativeBuildInputs = with pkgs; [makeWrapper];
      cargoTestExtraArgs = "-- --skip 'github::test::pagination' --skip 'github::test::finite_pagination'";
      postInstall = ''
        wrapProgram $out/bin/pr-tracker-fetcher --prefix PATH ":" ${lib.makeBinPath [pkgs.git]}
      '';
    };

    checks."packages/fetcher" = self'.packages.fetcher;
  };
}
