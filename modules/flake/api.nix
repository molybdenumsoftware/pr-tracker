{self, ...}: {
  flake.nixosModules.api.imports = [
    self.nixosModules.common
    ../nixos/api.nix
  ];
}
