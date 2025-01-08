{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  perSystem = {
    pre-commit.settings.hooks.nix-fmt = {
      enable = true;
      entry = "nix fmt -- --fail-on-change";
    };

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
