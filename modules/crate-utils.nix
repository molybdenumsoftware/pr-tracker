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
    toolchain = inputs'.fenix.packages.stable.toolchain;
    crane = craneLib.overrideToolchain toolchain;

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
      inherit (crane.crateNameFromCargoToml {inherit cargoToml;}) pname;

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
        crane
        ;
    };

    treefmt.programs.rustfmt = {
      enable = true;
      package = toolchain;
    };
  };
}
