{self, ...}: {
  flake.nixosModules.fetcher.imports = [
    self.nixosModules.common
    ../nixos/fetcher.nix
  ];
}
