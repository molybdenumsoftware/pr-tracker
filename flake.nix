{
  inputs = {
    # pinned to avoid a later broken rustfmt https://github.com/NixOS/nixpkgs/issues/273920
    nixpkgs.url = github:NixOS/nixpkgs/fb22f402f47148b2f42d4767615abb367c1b7cfd;

    by-name.url = "github:mightyiam/by-name";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    crane.url = "github:ipetkov/crane";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    fenix.url = "github:nix-community/fenix";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = {
    self,
    nixpkgs,
    by-name,
    crane,
    flake-utils,
    treefmt-nix,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;
    inherit
      (lib)
      attrValues
      optionalAttrs
      ;

    flattenTree = import ./flattenTree.nix;

    forEachDefaultSystem = system: let
      pkgs = nixpkgs.legacyPackages.${system};
      craneLib = crane.lib.${system};
      fenix = inputs.fenix.packages.${system};
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

      inherit (import ./packages {inherit lib pkgs by-name craneLib fenix;}) packages clippyCheck;

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
        packages = with pkgs; [sqlx-cli] ++ devUtils;
        SQLX_OFFLINE = "true";
      };

      checks = flattenTree {
        inherit packages nixosTests;
        clippy = clippyCheck;
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
