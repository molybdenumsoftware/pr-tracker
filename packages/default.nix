{
  lib,
  pkgs,
  by-name,
  craneLib,
  fenix,
  nixpkgs,
  nmdLib,
  pr-tracker,
  GITHUB_GRAPHQL_SCHEMA,
}: let
  inherit
    (lib)
    fileset
    filterAttrs
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
    ;

  src = fileset.toSource {
    root = ../.;
    fileset = fileset.unions [../crates ../Cargo.toml ../Cargo.lock];
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

    cargoToml = src + "/crates/${dir}/Cargo.toml";
    inherit (crateNameFromCargoToml {inherit cargoToml;}) pname;

    cargoExtraArgs = "--package ${pname}";

    pkgArgs =
      {
        inherit src pname cargoExtraArgs;
        meta.mainProgram = pname;

        cargoArtifacts = crane.buildDepsOnly {
          inherit src pname cargoExtraArgs;
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
      nixpkgs
      nmdLib
      pkgs
      src
      buildWorkspacePackage
      pr-tracker
      GITHUB_GRAPHQL_SCHEMA
      ;
  };

  byName = by-name.lib.trivial callPackage;
  packages = byName ./.;
in {inherit packages clippyCheck;}
