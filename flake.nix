{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    fenix.url = "github:nix-community/fenix";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    github-graphql-schema.flake = false;
    github-graphql-schema.url = "github:octokit/graphql-schema";
    nmd.inputs.nixpkgs.follows = "nixpkgs";
    nmd.url = "git+https://git.sr.ht/~rycee/nmd";
    systems.url = "github:nix-systems/default";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} ({inputs, ...}: {
      systems = import inputs.systems;
      imports = [
        ./modules/api
        ./modules/clippy.nix
        ./modules/crate-utils.nix
        ./modules/dev-shell.nix
        ./modules/fetcher
        ./modules/filter-options.nix
        ./modules/formatting.nix
        ./modules/integration-tests
        ./modules/nixos-manual
        ./modules/nixos-modules-lib.nix
        ./modules/private-nixos-modules
        ./modules/program-docs.nix
        ./modules/release
        ./modules/store.nix
        ./modules/util.nix
      ];
    });

  nixConfig.extra-experimental-features = ["pipe-operators"];
}
