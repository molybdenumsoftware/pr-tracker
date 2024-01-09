{
  lib,
  pkgs,
  by-name,
  craneLib,
}: let
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

  inherit
    (craneLib)
    cargoClippy
    crateNameFromCargoToml
    filterCargoSources
    ;

  rootPath = craneLib.path ../.;
  sqlxQueryFilter = path: type: hasPrefix "${rootPath}/crates/store/.sqlx/" path;
  migrationsFilter = path: type: hasPrefix "${rootPath}/crates/util/migrations/" path;

  srcFilter = path: type:
    any (p: p path type) [sqlxQueryFilter migrationsFilter filterCargoSources];

  src = cleanSourceWith {
    src = rootPath;
    filter = srcFilter;
  };

  title = "pr-tracker";

  cargoArtifacts = craneLib.buildDepsOnly {
    inherit src;
    pname = title;
    version = "unversioned";
  };

  clippyCheck = cargoClippy {
    inherit src cargoArtifacts;
    cargoClippyExtraArgs = "--all-targets --all-features -- --deny warnings";
    pname = title;
    version = "unversioned";
  };

  buildWorkspacePackage = dir: let
    cargoToml = rootPath + "/crates/${dir}/Cargo.toml";
    inherit (crateNameFromCargoToml {inherit cargoToml;}) pname version;

    pkgArgs = {
      inherit src cargoArtifacts pname version;
      nativeCheckInputs = with pkgs; [postgresql];
      meta.mainProgram = pname;
      cargoExtraArgs = "--package ${pname}";
    };
  in
    craneLib.buildPackage pkgArgs;

  callPackage = pkgs.newScope {inherit lib pkgs buildWorkspacePackage;};
  byName = by-name.lib.trivial callPackage;
  packages = byName ./.;
in {inherit packages clippyCheck;}
