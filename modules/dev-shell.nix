{ inputs, ... }:
{
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
