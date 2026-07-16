{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nci = {
      url = "github:yusdacra/nix-cargo-integration";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        parts.follows = "flake-parts";
        treefmt.follows = "treefmt-nix";
      };
    };
    devshell = {
      url = "github:numtide/devshell";
      flake = false;
    };
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    github-graphql-schema = {
      flake = false;
      url = "github:octokit/graphql-schema";
    };
    nmd = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "git+https://git.sr.ht/~rycee/nmd";
    };
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
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
          ./modules/manual.nix
          ./modules/prior-art.nix
          ./modules/introduction.nix
          ./modules/vision.nix
          ./modules/nci.nix
          ./modules/nixos-modules-lib.nix
          ./modules/private-nixos-modules
          ./modules/release
          ./modules/store.nix
          ./modules/util.nix
          ./modules/git-hooks.nix
        ];
      }
    );
}
