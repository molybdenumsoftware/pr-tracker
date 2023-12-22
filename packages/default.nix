{pkgs}: let
  inherit
    (pkgs.lib)
    fileset
    filterAttrs
    mapAttrs
    pipe
    ;

  inherit
    (builtins)
    readDir
    ;

  buildInputs = with pkgs; [pkg-config openssl];

  nativeCheckInputs = with pkgs; [postgresql clippy];

  cargoWorkspaceSrc = fileset.toSource {
    root = ../.;
    fileset = fileset.unions [
      ../Cargo.toml
      ../Cargo.lock
      ../crates
    ];
  };

  onlyDirs = filterAttrs (_name: type: type == "directory");
  callPackage = pkgs.newScope {inherit cargoWorkspaceSrc buildInputs nativeCheckInputs;};
  dirEntriesToPackageSet = mapAttrs (pkgDir: _type: callPackage (./. + "/${pkgDir}/package.nix") {});
  packageSet = pipe ./. [readDir onlyDirs dirEntriesToPackageSet];
in
  packageSet
