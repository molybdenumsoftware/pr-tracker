{
  lib,
  rustPlatform,
  gitMinimal,
  postgresql,
  octokit-graphql-schema,
  clippy,
}:
let
  projectRoot = ../..; # src.origSrc ?
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "pr-tracker";
  inherit ((lib.importTOML (projectRoot + "/Cargo.toml")).workspace.package) version;
  src = lib.fileset.toSource {
    root = projectRoot;
    fileset = lib.fileset.unions [
      (lib.fileset.fileFilter (
        file:
        lib.elem file.name [
          "Cargo.toml"
          "Cargo.lock"
        ]
      ) projectRoot)
      (lib.fileset.fileFilter (
        file:
        lib.any file.hasExt [
          "rs"
          "graphql"
          "sql"
        ]
      ) projectRoot)
      (projectRoot + "/.sqlx")
    ];
  };
  cargoLock.lockFile = (projectRoot + "/Cargo.lock");
  buildType = "debug";
  passthru.env = {
    CARGO_BUILD_WARNINGS = "deny";
    GIT = lib.getExe gitMinimal;
    POSTGRESQL_INITDB = lib.getExe' postgresql "initdb";
    POSTGRESQL_POSTGRES = lib.getExe' postgresql "postgres";
    OCTOKIT_GRAPHQL_SCHEMA = "${octokit-graphql-schema}/schema.graphql";
  };
  env = finalAttrs.passthru.env // {
    CARGO_BUILD_WARNINGS = "deny";
  };
  nativeCheckInputs = [ clippy ];
  preCheck = ''
    cargo clippy --all-targets --all-features
  '';
})
