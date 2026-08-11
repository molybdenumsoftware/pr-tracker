{ inputs, ... }:
{
  flake-file.inputs.devshell = {
    url = "github:numtide/devshell";
    flake = false;
  };
  imports = [
    "${inputs.devshell}/flake-module.nix"
  ];
  perSystem =
    { config, ... }:
    {
      nci.projects.default.numtideDevshell = "default";
      checks.devshell = config.devShells.default;
    };
}
