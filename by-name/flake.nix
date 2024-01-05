{
  outputs = {nixpkgs, ...}: {
    lib.byName = let
      inherit (nixpkgs.lib) pipe filterAttrs;
      inherit (builtins) mapAttrs readDir;
    in
      callPackage: path: let
        onlyDirs = filterAttrs (_name: type: type == "directory");
        dirEntriesToPackageSet = mapAttrs (pkgDir: _type: callPackage (path + "/${pkgDir}/package.nix") {});
        packageSet = pipe path [readDir onlyDirs dirEntriesToPackageSet];
      in
        packageSet;
  };
}
