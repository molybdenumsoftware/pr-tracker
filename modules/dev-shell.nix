{ inputs, ... }:
{
  imports = [
    inputs.devshell.flakeModule
  ];
  perSystem =
    { config, ... }:
    {
      nci.projects.default.numtideDevshell = "default";
      checks.devshell = config.devShells.default;
    };
}
