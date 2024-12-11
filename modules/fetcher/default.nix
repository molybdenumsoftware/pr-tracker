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
<<<<<<< Updated upstream
    packages.fetcher = buildWorkspacePackage {
      inherit GITHUB_GRAPHQL_SCHEMA;
      env = {
        POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
        POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
        GIT = lib.getExe pkgs.git;
      };
||||||| Stash base
    packages.fetcher = buildWorkspacePackage {
      inherit GITHUB_GRAPHQL_SCHEMA;
=======
    nci.crates.pr-tracker-fetcher.drvConfig = {
      mkDerivation = {
        nativeCheckInputs = with pkgs; [git postgresql];
        nativeBuildInputs = with pkgs; [makeWrapper];
>>>>>>> Stashed changes

<<<<<<< Updated upstream
      dir = "fetcher";
||||||| Stash base
      dir = "fetcher";
      nativeCheckInputs = with pkgs; [git postgresql];
      nativeBuildInputs = with pkgs; [makeWrapper];
      postInstall = ''
        wrapProgram $out/bin/pr-tracker-fetcher --prefix PATH ":" ${lib.makeBinPath [pkgs.git]}
      '';
=======
        postInstall = ''
          wrapProgram $out/bin/pr-tracker-fetcher --prefix PATH ":" ${lib.makeBinPath [pkgs.git]}
        '';
      };
      env = {inherit GITHUB_GRAPHQL_SCHEMA;};
>>>>>>> Stashed changes
    };

    packages.fetcher = config.nci.outputs.pr-tracker-fetcher.packages.release;
    checks."packages/fetcher" = self'.packages.fetcher;
  };
}
