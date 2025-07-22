{ inputs, ... }:
{
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
