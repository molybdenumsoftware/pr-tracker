{ lib, inputs, ... }:
{
  perSystem =
    psArgs@{ pkgs, ... }:
    {
      options = {
        env = lib.mkOption {
          readOnly = true;
          type = lib.types.lazyAttrsOf (lib.types.either lib.types.str lib.types.package);
          default = {
            CARGO_BUILD_WARNINGS = "deny";
            GIT = lib.getExe pkgs.gitMinimal;
            POSTGRESQL_INITDB = lib.getExe' pkgs.postgresql "initdb";
            POSTGRESQL_POSTGRES = lib.getExe' pkgs.postgresql "postgres";
            GITHUB_GRAPHQL_SCHEMA = "${inputs.github-graphql-schema}/schema.graphql";
          };
        };
        package = lib.mkOption {
          readOnly = true;
          type = lib.types.package;
          default = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
            pname = "pr-tracker";
            inherit ((lib.importTOML ../Cargo.toml).workspace.package) version;
            src = lib.fileset.toSource {
              root = ../.;
              inherit (psArgs.config) fileset;
            };
            cargoLock.lockFile = ../Cargo.lock;
            buildType = "debug";
            env = psArgs.config.env // {
              CARGO_BUILD_WARNINGS = "deny";
            };
            nativeCheckInputs = [ pkgs.clippy ];
            preCheck = ''
              cargo clippy --all-targets --all-features
            '';
          });
        };
      };
      config.checks = { inherit (psArgs.config) package; };
    };
}
