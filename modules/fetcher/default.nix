{
  inputs,
  GITHUB_GRAPHQL_SCHEMA,
  ...
}: {
  imports = [./nixos-module.nix];

  _module.args.GITHUB_GRAPHQL_SCHEMA = "${inputs.github-graphql-schema}/schema.graphql";

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
      postInstall = ''
        wrapProgram $out/bin/pr-tracker-fetcher --prefix PATH ":" ${lib.makeBinPath [pkgs.git]}
      '';
    };

    checks."packages/fetcher" = self'.packages.fetcher;
  };
}
