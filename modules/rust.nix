{ inputs, lib, ... }: {
  flake-file.inputs.crate2nix = {
    url = "github:nix-community/crate2nix";
    flake = false;
  };

  perSystem =
    psArgs@{ pkgs, ... }:
    {
      options = {
        defaultCrateOverrides = lib.mkOption {
          type = lib.types.lazyAttrsOf (lib.types.functionTo (lib.types.lazyAttrsOf lib.types.anything));
        };
        crate2nix = {
          crate2nix = lib.mkOption {
            type = lib.types.package;
            readOnly = true;
            default = pkgs.callPackage "${inputs.crate2nix}/crate2nix" { };
          };

          crate2nix-tools = lib.mkOption {
            type = lib.types.unspecified;
            readOnly = true;
            default = pkgs.callPackage "${inputs.crate2nix}/tools.nix" { };
          };

          generatedCargoNix = lib.mkOption {
            type = lib.types.package;
            readOnly = true;
            default = psArgs.config.crate2nix.crate2nix-tools.generatedCargoNix {
              name = "pr-tracker";
              src = lib.fileset.toSource {
                root = ../.;
                fileset = psArgs.config.fileset;
              };
            };
          };

          workspace = lib.mkOption {
            type = lib.types.unspecified;
            readOnly = true;
            default = pkgs.callPackage psArgs.config.crate2nix.generatedCargoNix {
              buildRustCrateForPkgs =
                pkgs':
                pkgs'.buildRustCrate.override {
                  defaultCrateOverrides = pkgs'.defaultCrateOverrides // psArgs.config.defaultCrateOverrides;
                };
            };
          };
        };
      };

      config = {
        treefmt.programs.rustfmt.enable = true;
        devshells.default.packages = with pkgs; [
          cargo
          clippy
          rust-analyzer-unwrapped # https://github.com/NixOS/nixpkgs/issues/212439
          rustc
        ];
      };
    };
}
# TODO
# [] make sure build settings are good for debugging, symbols and whatnot
# [] make sure tests are run in builds
# [] make sure to deny warnings in builds
