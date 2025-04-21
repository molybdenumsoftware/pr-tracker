{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nci.url = "github:yusdacra/nix-cargo-integration";
    nci.inputs.nixpkgs.follows = "nixpkgs";
    nci.inputs.parts.follows = "flake-parts";
    nci.inputs.treefmt.follows = "treefmt-nix";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    github-graphql-schema.flake = false;
    github-graphql-schema.url = "github:octokit/graphql-schema";
    nmd.inputs.nixpkgs.follows = "nixpkgs";
    nmd.url = "git+https://git.sr.ht/~rycee/nmd";
    systems.url = "github:nix-systems/default";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { inputs, ... }:
      {
        systems = import inputs.systems;
        imports = [
          ./modules/api
          ./modules/db-context.nix
          ./modules/dev-shell.nix
          ./modules/fetcher
          ./modules/filter-options.nix
          ./modules/formatting.nix
          ./modules/integration-tests
          ./modules/nci.nix
          ./modules/nixos-manual
          ./modules/nixos-modules-lib.nix
          ./modules/private-nixos-modules
          ./modules/program-docs.nix
          ./modules/release
          ./modules/store.nix
          ./modules/util.nix
          ./modules/git-hooks.nix
        ];
      }
    );
}
