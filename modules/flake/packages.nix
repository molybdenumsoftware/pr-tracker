{
  inputs,
  lib,
  self,
  GITHUB_GRAPHQL_SCHEMA,
  ...
}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    craneLib = inputs.crane.mkLib pkgs;
    fenix = inputs.fenix.packages.${system};
    crane = craneLib.overrideToolchain fenix.stable.toolchain;
    src = lib.fileset.toSource {
      root = ../..;
      fileset = lib.fileset.unions [../../crates ../../Cargo.toml ../../Cargo.lock];
    };

    nmdLib = inputs.nmd.lib.${system};
    title = "pr-tracker";

    cargoArtifacts = crane.buildDepsOnly {
      inherit src;
      pname = title;
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

    callPackage = pkgs.newScope {
      inherit
        cargoArtifacts
        lib
        nmdLib
        pkgs
        src
        buildWorkspacePackage
        GITHUB_GRAPHQL_SCHEMA
        ;

      inherit
        (craneLib)
        cargoDoc
        ;

      inherit (inputs) nixpkgs;

      pr-tracker = self;
    };
    packages = lib.filesystem.packagesFromDirectoryRecursive {
      inherit callPackage;
      directory = "${self}/packages";
    };
  in {
    inherit packages;

    checks = import "${self}/flattenTree.nix" {
      inherit packages;
      clippy = craneLib.cargoClippy {
        inherit src GITHUB_GRAPHQL_SCHEMA cargoArtifacts;
        cargoClippyExtraArgs = "--all-targets --all-features -- --deny warnings";
        pname = title;
        version = "unversioned";
      };
    };
  };
}
