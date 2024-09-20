({
  self,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: {
    checks = import ../../flattenTree.nix {
      nixosTests = lib.packagesFromDirectoryRecursive {
        callPackage = pkgs.newScope {pr-tracker = self;};
        directory = ../../nixos-tests;
      };
    };
  };
})
