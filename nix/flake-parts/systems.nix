{ inputs, ... }: {
  flake-file.inputs.systems = {
    url = "github:nix-systems/default";
    flake = false;
  };
  systems = import inputs.systems;
}
