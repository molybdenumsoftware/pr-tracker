{
  inputs,
  GITHUB_GRAPHQL_SCHEMA,
  ...
}: {
  imports = [./nixos-module.nix];

  _module.args.GITHUB_GRAPHQL_SCHEMA = "${inputs.github-graphql-schema}/schema.graphql";

  perSystem = {
    self',
    config,
    pkgs,
    lib,
    ...
  }: {
    nci.crates.pr-tracker-fetcher.drvConfig = {
      mkDerivation = {
        nativeCheckInputs = with pkgs; [git postgresql];
        nativeBuildInputs = with pkgs; [makeWrapper];

        postInstall = ''
          wrapProgram $out/bin/pr-tracker-fetcher --prefix PATH ":" ${lib.makeBinPath [pkgs.git]}
        '';
      };
      env = {inherit GITHUB_GRAPHQL_SCHEMA;};
    };

    packages.fetcher = config.nci.outputs.pr-tracker-fetcher.packages.release;
    checks."packages/fetcher" = self'.packages.fetcher;
  };
}
