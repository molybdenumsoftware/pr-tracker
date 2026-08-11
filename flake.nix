{
  nixConfig = {
    abort-on-warn = true;
  };

  inputs = {
    import-tree.url = "github:denful/import-tree";
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
      flake = false;
    };
    github-graphql-schema = {
      url = "github:octokit/graphql-schema";
      flake = false;
    };
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
  };

  outputs = inputs: import ./outputs.nix inputs;
}
