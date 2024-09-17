{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    fenix.url = "github:nix-community/fenix";
    flake-utils.url = "github:numtide/flake-utils";
    github-graphql-schema.flake = false;
    github-graphql-schema.url = "github:octokit/graphql-schema";
    nmd.inputs.nixpkgs.follows = "nixpkgs";
    nmd.url = "git+https://git.sr.ht/~rycee/nmd";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = {
    self,
    nixpkgs,
    crane,
    flake-utils,
    github-graphql-schema,
    nmd,
    treefmt-nix,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;
    inherit
      (lib)
      attrValues
      mkOption
      ;

    flattenTree = import ./flattenTree.nix;

    GITHUB_GRAPHQL_SCHEMA = "${github-graphql-schema}/schema.graphql";

    forEachDefaultSystem = system: let
      pkgs = nixpkgs.legacyPackages.${system};
      craneLib = crane.mkLib pkgs;
      fenix = inputs.fenix.packages.${system};
      nmdLib = nmd.lib.${system};
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

      inherit
        (pkgs)
        mkShell
        newScope
        sqlx-cli
        writeShellApplication
        ;

      inherit
        (import ./packages.nix {
          inherit lib pkgs craneLib fenix nixpkgs nmdLib GITHUB_GRAPHQL_SCHEMA;
          pr-tracker = self;
        })
        packages
        clippyCheck
        ;

      devUtils = [
        (writeShellApplication {
          name = "util-sqlx-prepare";
          runtimeInputs = [sqlx-cli];
          text = "cargo run --package util --bin sqlx-prepare";
        })

        (writeShellApplication {
          name = "util-db-repl";
          text = "cargo run --package util --bin db-repl";
        })
      ];

      nixosTests = lib.packagesFromDirectoryRecursive {
        callPackage = newScope {pr-tracker = self;};
        directory = ./nixos-tests;
      };
    in {
      inherit packages;

      apps = import ./release {inherit pkgs flake-utils;};

      devShells.default = mkShell {
        inherit GITHUB_GRAPHQL_SCHEMA;
        inputsFrom = attrValues packages;
        packages = [sqlx-cli] ++ devUtils;
        SQLX_OFFLINE = "true";
      };

      checks = flattenTree {
        inherit packages nixosTests;
        clippy = clippyCheck;
        formatting = treefmtEval.config.build.check self;
        filterOptions = assert (import ./filterOptions-check.nix lib); pkgs.hello;
      };

      formatter = treefmtEval.config.build.wrapper;
    };
    systemSpecificOutputs = flake-utils.lib.eachDefaultSystem forEachDefaultSystem;

    mkPublicModule = path: {pkgs, ...}: {
      imports = [path];
      options._pr-tracker-packages = mkOption {internal = true;};
      config._pr-tracker-packages = self.packages.${pkgs.system};
    };

    systemAgnosticOutputs.nixosModules.api = mkPublicModule ./modules/api.nix;
    systemAgnosticOutputs.nixosModules.fetcher = mkPublicModule ./modules/fetcher.nix;
  in
    systemSpecificOutputs
    // systemAgnosticOutputs;
}
