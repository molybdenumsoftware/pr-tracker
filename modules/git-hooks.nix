{ inputs, ... }:
{
  flake-file.inputs.git-hooks-nix = {
    url = "github:cachix/git-hooks.nix";
    flake = false;
  };
  imports = [ "${inputs.git-hooks-nix}/flake-module.nix" ];
  perSystem =
    { config, ... }:
    {
      pre-commit.check.enable = false;
      devshells.default.devshell.startup.git-hooks.text = config.pre-commit.installationScript;
    };
}
