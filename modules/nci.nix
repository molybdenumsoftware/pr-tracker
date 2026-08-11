{
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.nci.flakeModule ];

  config = {
    flake-file.inputs.nci = {
      url = "github:yusdacra/nix-cargo-integration";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        parts.follows = "flake-parts";
        treefmt.follows = "treefmt-nix";
      };
    };

    perSystem =
      psArgs@{
        pkgs,
        ...
      }:
      {

        nci.projects.default = {
          path = lib.fileset.toSource {
            root = ../.;
            fileset = psArgs.config.fileset;
          };

          profiles = {
            dev = { };
            release.runTests = true;
          };
          clippyProfile = "release";
          drvConfig.env.RUSTFLAGS = "--deny warnings";
          export = false;
        };
        devshells.default.devshell = {
          startup.rust-warn-warnings.text = ''
            export RUSTFLAGS="$RUSTFLAGS --warn warnings"
          '';
          packages = [
            pkgs.rust-analyzer-unwrapped # https://github.com/NixOS/nixpkgs/issues/212439
          ];
        };
        treefmt.programs.rustfmt = {
          enable = true;
          package = psArgs.config.nci.toolchains.mkBuild pkgs;
        };
      };
  };
}
