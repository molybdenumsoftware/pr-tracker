{ inputs, ... }:
{
  flake-file.inputs.git-hooks-nix = {
    url = "github:cachix/git-hooks.nix";
    flake = false;
  };
  imports = [ "${inputs.git-hooks-nix}/flake-module.nix" ];
  perSystem = psArgs: {
    pre-commit.check.enable = false;
    devshells.default.devshell.startup.git-hooks.text = psArgs.config.pre-commit.installationScript;
  };
}
