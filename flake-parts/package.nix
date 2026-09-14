{
  lib,
  inputs,
  config,
  ...
}:
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
            inherit ((lib.importTOML (config.projectRoot + "/Cargo.toml")).workspace.package) version;
            src = lib.fileset.toSource {
              root = config.projectRoot;
              fileset = lib.fileset.unions [
                (lib.fileset.fileFilter (
                  file:
                  lib.elem file.name [
                    "Cargo.toml"
                    "Cargo.lock"
                  ]
                ) config.projectRoot)
                (lib.fileset.fileFilter (
                  file:
                  lib.any file.hasExt [
                    "rs"
                    "graphql"
                    "sql"
                  ]
                ) config.projectRoot)
                (config.projectRoot + "/.sqlx")
              ];
            };
            cargoLock.lockFile = (config.projectRoot + "/Cargo.lock");
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
