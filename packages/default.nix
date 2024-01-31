{
  lib,
  pkgs,
  by-name,
  fenix,
  GITHUB_GRAPHQL_SCHEMA,
  ...
} @ args: let
  inherit
    (lib)
    any
    cleanSourceWith
    fileset
    filterAttrs
    hasPrefix
    mapAttrs
    pipe
    recursiveUpdate
    ;

  inherit
    (builtins)
    readDir
    removeAttrs
    ;

  craneLib = args.craneLib.overrideToolchain fenix.stable.toolchain;

  inherit
    (craneLib)
    cargoClippy
    crateNameFromCargoToml
    filterCargoSources
    ;

  rootPath = craneLib.path ../.;
  sqlxQueryFilter = path: type: hasPrefix "${rootPath}/crates/store/.sqlx/" path;
  migrationsFilter = path: type: hasPrefix "${rootPath}/crates/store/migrations/" path;
  graphQlFilter = path: type: hasPrefix "${rootPath}/crates/fetcher/src/graphql/" path;

  srcFilter = path: type:
    any (p: p path type) [sqlxQueryFilter migrationsFilter graphQlFilter filterCargoSources];

  src = cleanSourceWith {
    src = rootPath;
    filter = srcFilter;
  };

  title = "pr-tracker";

  clippyCheck = cargoClippy {
    inherit src GITHUB_GRAPHQL_SCHEMA;
    cargoArtifacts = craneLib.buildDepsOnly {
      inherit src;
      pname = title;
      version = "unversioned";
    };
    cargoClippyExtraArgs = "--all-targets --all-features -- --deny warnings";
    pname = title;
    version = "unversioned";
  };

  buildWorkspacePackage = args @ {dir, ...}: let
    cleanedArgs = removeAttrs args ["dir"];

    cargoToml = rootPath + "/crates/${dir}/Cargo.toml";
    inherit (crateNameFromCargoToml {inherit cargoToml;}) pname version;

    cargoExtraArgs = "--package ${pname}";

    pkgArgs =
      {
        inherit src pname version cargoExtraArgs;
        meta.mainProgram = pname;

        cargoArtifacts = craneLib.buildDepsOnly {
          inherit src pname version cargoExtraArgs;
        };
      }
      // cleanedArgs;
  in
    craneLib.buildPackage pkgArgs;

  callPackage = pkgs.newScope {
    inherit
      lib
      pkgs
      buildWorkspacePackage
      GITHUB_GRAPHQL_SCHEMA
      ;
  };

  byName = by-name.lib.trivial callPackage;
  packages = byName ./.;
in {inherit packages clippyCheck;}
