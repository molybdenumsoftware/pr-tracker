{
  inputs,
  lib,
  ...
}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    craneLib = inputs.crane.mkLib pkgs;
    fenix = inputs'.fenix.packages;
    crane = craneLib.overrideToolchain fenix.stable.toolchain;

    src = lib.fileset.toSource {
      root = ../.;
      fileset = lib.fileset.unions [../crates ../Cargo.toml ../Cargo.lock];
    };

    cargoArtifacts = crane.buildDepsOnly {
      inherit src;
      pname = "pr-tracker";
      version = "unversioned";
    };

    buildWorkspacePackage = args @ {dir, ...}: let
      cleanedArgs = removeAttrs args ["dir"];

      cargoToml = src + "/crates/${dir}/Cargo.toml";
      inherit (craneLib.crateNameFromCargoToml {inherit cargoToml;}) pname;

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
  in {
    _module.args = {
      inherit
        cargoArtifacts
        buildWorkspacePackage
        src
        craneLib
        ;
    };
  };
}
