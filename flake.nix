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
      _module.args.GITHUB_GRAPHQL_SCHEMA = "${inputs.github-graphql-schema}/schema.graphql";
      imports = [
        ./modules/flake/api.nix
        ./modules/flake/checks.nix
        ./modules/flake/dev-shell.nix
        ./modules/flake/fetcher.nix
        ./modules/flake/filterOptions-check.nix
        ./modules/flake/formatting.nix
        ./modules/flake/nixos-common.nix
        ./modules/flake/packages.nix
        ./modules/flake/release
      ];
    });
}
