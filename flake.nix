# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: import ./nix/outputs.nix inputs;

  nixConfig = {
    abort-on-warn = true;
  };

  inputs = {
    devshell = {
      url = "github:numtide/devshell";
      flake = false;
    };
    files = {
      url = "github:mightyiam/files";
      flake = false;
    };
    flake-file = {
      url = "github:denful/flake-file";
      flake = false;
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      flake = false;
    };
    import-tree = {
      url = "github:denful/import-tree";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    octokit-graphql-schema = {
      url = "github:octokit/graphql-schema";
      flake = false;
    };
    systems = {
      url = "github:nix-systems/default";
      flake = false;
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
