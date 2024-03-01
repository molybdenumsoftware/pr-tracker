{
  lib,
  pkgs,
  by-name,
  craneLib,
  fenix,
  GITHUB_GRAPHQL_SCHEMA,
}: let
  inherit
    (lib)
    any
    cleanSourceWith
    fileset
    filterAttrs
    hasPrefix
    hasSuffix
    mapAttrs
    pipe
    recursiveUpdate
    ;

  inherit
    (builtins)
    readDir
    removeAttrs
    ;

  inherit
    (pkgs)
    newScope
    ;

  crane = craneLib.overrideToolchain fenix.stable.toolchain;

  inherit
    (crane)
    cargoClippy
    cargoDoc
    crateNameFromCargoToml
    filterCargoSources
    ;

  rootPath = crane.path ../.;
  sqlxQueryFilter = path: type: hasPrefix "${rootPath}/crates/store/.sqlx/" path;
  migrationsFilter = path: type: hasPrefix "${rootPath}/crates/util/migrations/" path;
  graphQlFilter = path: type: hasPrefix "${rootPath}/crates/fetcher/src/graphql/" path;
  docsFilter = path: type: (hasPrefix "${rootPath}/crates/" path) && (hasSuffix ".md" path);

  srcFilter = path: type:
    any (p: p path type) [sqlxQueryFilter migrationsFilter graphQlFilter filterCargoSources docsFilter];

  src = cleanSourceWith {
    src = rootPath;
    filter = srcFilter;
  };

  title = "pr-tracker";

  cargoArtifacts = crane.buildDepsOnly {
    inherit src;
    pname = title;
    version = "unversioned";
  };

  clippyCheck = cargoClippy {
    inherit src GITHUB_GRAPHQL_SCHEMA cargoArtifacts;
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

        cargoArtifacts = crane.buildDepsOnly {
          inherit src pname version cargoExtraArgs;
        };
      }
      // cleanedArgs;
  in
    crane.buildPackage pkgArgs;

  callPackage = newScope {
    inherit
      cargoArtifacts
      cargoDoc
      lib
      pkgs
      src
      buildWorkspacePackage
      GITHUB_GRAPHQL_SCHEMA
      ;
  };

  byName = by-name.lib.trivial callPackage;
  packages = byName ./.;
in {inherit packages clippyCheck;}
