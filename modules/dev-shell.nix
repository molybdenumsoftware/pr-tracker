{ inputs, ... }:
{
  flake-file.inputs.devshell = {
    url = "github:numtide/devshell";
    flake = false;
  };
  imports = [
    "${inputs.devshell}/flake-module.nix"
  ];
  perSystem = psArgs: {
    checks.devshell = psArgs.config.devShells.default;
  };
}
