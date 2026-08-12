{ inputs, ... }:
{
  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  perSystem = {
    pre-commit.settings.hooks.treefmt.enable = true;

    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt.enable = true;
        prettier.enable = true;
        toml-sort = {
          enable = true;
          all = true;
        };
      };
    };
  };
}
