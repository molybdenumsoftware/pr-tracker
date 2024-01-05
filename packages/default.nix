{
  pkgs,
  by-name,
}: let
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

  callPackage = pkgs.newScope {inherit cargoWorkspaceSrc buildInputs nativeCheckInputs;};
  byName = by-name.lib.byName callPackage;
  packageSet = byName ./.;
in
  packageSet
