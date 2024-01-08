{
  inputs = {
    # pinned to avoid a later broken rustfmt https://github.com/NixOS/nixpkgs/issues/273920
    nixpkgs.url = github:NixOS/nixpkgs/fb22f402f47148b2f42d4767615abb367c1b7cfd;
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    by-name.url = "github:mightyiam/by-name";
  };

  outputs = {
    self,
    nixpkgs,
    treefmt-nix,
    flake-utils,
    by-name,
  }: let
    inherit (nixpkgs) lib;
    inherit
      (lib)
      attrValues
      optionalAttrs
      ;

    forEachDefaultSystem = system: let
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

      packages = import ./packages {inherit lib pkgs by-name;};

      devUtils = [
        (pkgs.writeShellApplication {
          name = "util-sqlx-prepare";
          runtimeInputs = [pkgs.sqlx-cli];
          text = "cargo run --package util --bin sqlx-prepare";
        })

        (pkgs.writeShellApplication {
          name = "util-db-repl";
          text = "cargo run --package util --bin db-repl";
        })
      ];

      nixosTests = {
        api-module = import ./nixos-tests/api.nix {
          modules = systemAgnosticOutputs.nixosModules;
          inherit lib pkgs;
        };
      };
    in {
      inherit packages;

      devShells.default = pkgs.mkShell {
        inputsFrom = attrValues packages;
        packages = with pkgs;
          [
            rustfmt
            rust-analyzer
            sqlx-cli
          ]
          ++ devUtils;
        SQLX_OFFLINE = "true";
      };

      checks =
        packages
        // nixosTests
        // {
          formatting = treefmtEval.config.build.check self;
        };

      formatter = treefmtEval.config.build.wrapper;
    };
    systemSpecificOutputs = flake-utils.lib.eachDefaultSystem forEachDefaultSystem;
    systemAgnosticOutputs = {
      nixosModules.api = import ./modules/api.nix {pr-tracker = self;};
    };
  in
    systemSpecificOutputs
    // systemAgnosticOutputs;
}
