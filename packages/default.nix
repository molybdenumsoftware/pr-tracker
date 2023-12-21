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

  buildInputs =
    if pkgs.stdenv.isDarwin
    then with pkgs; [darwin.apple_sdk.frameworks.SystemConfiguration]
    else if pkgs.stdenv.isLinux
    then with pkgs; [pkg-config openssl]
    else throw "unsupported";

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
