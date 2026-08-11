{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
{
  imports = [ inputs.nci.flakeModule ];

  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.nci.projects = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submoduleWith {
          modules = [
            {
              options.fileset = lib.mkOption {
                type = lib.mkOptionType {
                  name = "fileset";
                  merge = _loc: defs: lib.fileset.unions (map (def: def.value) defs);
                };
              };
            }
          ];
        }
      );
    };
  };

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
            fileset = psArgs.config.nci.projects.default.fileset;
          };

          fileset = lib.fileset.unions (
            [
              ../Cargo.toml
              ../Cargo.lock
            ]
            ++ (lib.pipe ../crates [
              builtins.readDir
              (lib.filterAttrs (name: type: type == "directory"))
              (lib.mapAttrsToList (
                name: type: [
                  (../crates + "/${name}/Cargo.toml")
                  (lib.fileset.maybeMissing (../crates + "/${name}/build.rs"))
                  (../crates + "/${name}/src")
                ]
              ))
              lib.flatten
            ])
          );

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
