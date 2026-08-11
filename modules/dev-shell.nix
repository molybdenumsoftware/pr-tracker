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
    nci.projects.default.numtideDevshell = "default";
    checks.devshell = psArgs.config.devShells.default;
  };
}
